import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import 'package:mony_time/src/services/storage_service.dart';
import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/bank_sync/data/datasources/bank_capture_local_data_source.dart';
import 'package:mony_time/src/features/bank_sync/data/datasources/bank_sync_remote_data_source.dart';
import 'package:mony_time/src/features/bank_sync/data/helpers/sms_batch_chunker.dart';
import 'package:mony_time/src/features/bank_sync/data/models/raw_sms.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_link.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_sync_results.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_sync_summary.dart';
import 'package:mony_time/src/features/bank_sync/domain/repositories/bank_sync_repository.dart';
import 'package:mony_time/src/shared/enums/transaction_type.dart';

/// Wraps the API and the native capture with `runTask` so every call returns
/// `Either<Failure, T>`.
///
/// Keeps the last bank catalog in memory: the capture's sender filter is the
/// linked banks' `sender_ids` (exact, trimmed, case-insensitive — the same
/// match the server applies).
class BankSyncRepositoryImpl implements BankSyncRepository {
  BankSyncRepositoryImpl(
    this._remote,
    this._capture, {
    BankLinkMethod? deviceMethod,
    StorageService? storage,
  })  : _deviceMethod = deviceMethod ??
            (PlatformInfo.isIOS
                ? BankLinkMethod.shortcuts
                : BankLinkMethod.sms),
        _storage = storage ?? StorageService.instance;

  final BankSyncRemoteDataSource _remote;
  final BankCaptureLocalDataSource _capture;
  final BankLinkMethod _deviceMethod;
  final StorageService _storage;

  List<Bank> _banks = const [];

  static const int _idsPerCall = 200;
  static const Duration _historyWindow = Duration(days: 30);

  /// Device inbox time up to which the catch-up scan has looked (Android).
  /// Set when capture is armed, so a catch-up never re-imports the past the
  /// user chose not to scan; overlapped a little on every read, since the
  /// server drops duplicates anyway.
  static const String _catchUpKey = 'bank_sync.catch_up_ms';
  static const Duration _catchUpOverlap = Duration(minutes: 5);

  @override
  bool get hasSession => _remote.hasSession;

  @override
  Stream<void> get capturedMessages => _capture.captured;

  @override
  BankLinkMethod get deviceMethod => _deviceMethod;

  @override
  FutureEither<List<Bank>> getSupportedBanks() {
    return runTask(() async => _banks = await _remote.getBanks());
  }

  @override
  FutureEither<BankLink> getLink() => runTask(() => _remote.getLink());

  @override
  FutureEither<BankLink> connect({
    required List<String> bankIds,
    required ImportMode mode,
  }) {
    return runTask(() async {
      final (link, token) = await _remote.connect(
        method: _deviceMethod,
        bankIds: bankIds,
        mode: mode,
      );
      // Shown only in this response: hand it to the Keystore/Keychain now.
      await _arm(token, link.bankIds);
      return link;
    });
  }

  @override
  FutureEither<BankLink> updateLink({
    required List<String> bankIds,
    required ImportMode mode,
  }) {
    return runTask(() async {
      final link = await _remote.updateLink(bankIds: bankIds, mode: mode);
      if (link.method == _deviceMethod) {
        await _capture.updateSenders(await _sendersFor(link.bankIds));
      }
      return link;
    });
  }

  @override
  FutureEither<void> disconnect() {
    return runTask(() async {
      await _remote.disconnect();
      await _standDown();
    });
  }

  @override
  FutureEither<CaptureReport> ensureCapture(BankLink link) {
    return runTask(() async {
      // One live ingest token per account. Connecting on the phone of the
      // other platform revoked whatever this one held, and re-issuing here
      // would cut that phone off — so this device just stands down.
      if (!link.isConnected || link.method != _deviceMethod) {
        await _standDown();
        return (outcome: CaptureOutcome.standingDown, caughtUp: 0);
      }

      final senders = await _sendersFor(link.bankIds);
      final status = await _capture.status();
      if (status.configured) {
        // Revoked while we held it: another phone of this platform took
        // over (or the password changed). Re-issuing automatically would
        // make two phones revoke each other forever; the user claims it
        // back from the hub instead.
        if (status.needsToken) {
          return (outcome: CaptureOutcome.revoked, caughtUp: 0);
        }
        await _capture.updateSenders(senders);
        if (status.queued > 0) await _capture.flush();
        return (
          outcome: CaptureOutcome.armed,
          caughtUp: await _catchUp(senders),
        );
      }

      // Nothing stored (fresh install, cleared data): this phone is the one
      // being set up, so it takes the token.
      final armed = await _reissue(senders);
      return (
        outcome: armed ? CaptureOutcome.armed : CaptureOutcome.standingDown,
        caughtUp: 0,
      );
    });
  }

  @override
  FutureEither<void> reissueCapture() {
    return runTask(() async {
      final bankIds = (await _remote.getLink()).bankIds;
      await _reissue(await _sendersFor(bankIds));
    });
  }

  @override
  FutureEither<void> stopCapture() => runTask(_standDown);

  @override
  FutureEither<HistoryScanResult> importRecentHistory({
    required List<String> bankIds,
  }) {
    return runTask(() async {
      final scannedAt = DateTime.now();
      final senders = await _sendersFor(bankIds);
      final sms = await _capture.readInbox(
        since: scannedAt.subtract(_historyWindow),
        senders: senders,
      );
      var created = 0, duplicates = 0, rejected = 0, pending = 0;
      for (final chunk in SmsBatchChunker.chunk(_wire(sms))) {
        final upload = await _uploadWithRetry(chunk, channel: 'history_scan');
        created += upload.created;
        duplicates += upload.duplicates;
        rejected += upload.rejected;
        pending += upload.pendingCreated;
      }
      // The catch-up continues from here.
      await _storage.setInt(_catchUpKey, scannedAt.millisecondsSinceEpoch);
      return HistoryScanResult(
        found: sms.length,
        created: created,
        duplicates: duplicates,
        rejected: rejected,
        pendingCreated: pending,
      );
    });
  }

  @override
  FutureEither<BankSyncSummary> getSummary() =>
      runTask(() => _remote.getSummary());

  @override
  FutureEither<BankMessagePage> getMessages({
    required BankMessageStatus status,
    String? cursor,
    int limit = 100,
  }) {
    return runTask(
      () => _remote.getMessages(status: status, cursor: cursor, limit: limit),
    );
  }

  @override
  FutureEither<BankMessage> getMessage(String id) =>
      runTask(() => _remote.getMessage(id));

  @override
  FutureEither<SubmittedBankMessage> submitMessage({
    required String sender,
    required String body,
  }) {
    return runTask(
      () => _remote.createMessage(
        sender: sender,
        body: body,
        receivedAt: DateTime.now(),
      ),
    );
  }

  @override
  FutureEither<List<BankMessage>> setStatus(
    List<String> ids,
    BankMessageStatus status,
  ) {
    return runTask(() async {
      final moved = <BankMessage>[];
      for (final chunk in _chunks(ids)) {
        moved.addAll(await _remote.setStatus(chunk, status));
      }
      return moved;
    });
  }

  @override
  FutureEither<BankImportResult> importMessage(
    String id,
    ImportOverrides overrides,
  ) {
    return runTask(() => _remote.importMessage(id, overrides));
  }

  @override
  FutureEither<BulkImportResult> importMessages(List<String> ids) {
    return runTask(() async {
      final imported = <BankImportResult>[];
      final skipped = <String, ImportSkipReason>{};
      for (final chunk in _chunks(ids)) {
        final result = await _remote.importMessages(chunk);
        imported.addAll(result.imported);
        skipped.addAll(result.skipped);
      }
      return BulkImportResult(imported: imported, skipped: skipped);
    });
  }

  @override
  FutureEither<List<BankCategory>> getCategories(TransactionType type) {
    return runTask(() => _remote.getCategories(type));
  }

  // ── Capture helpers ────────────────────────────────────────────────────────

  /// Issues a token for this device and arms capture with it. `false` when
  /// the server has no link any more (then nothing is left armed).
  Future<bool> _reissue(List<String> senders) async {
    final String token;
    try {
      token = await _remote.reissueIngestToken();
    } on DioException catch (e) {
      if (ApiError.fromDio(e)?.code == 'NOT_CONNECTED') {
        await _standDown();
        return false;
      }
      rethrow;
    }
    await _arm(token, null, senders: senders);
    return true;
  }

  /// Hands [token] to native storage and starts the catch-up window now.
  ///
  /// The server already holds the link when this runs: a Keystore that
  /// refuses to seal the token must not fail the connect. The failure is
  /// logged, the user keeps the inbox and the paste sheet, and the next
  /// `ensureCapture` finds nothing stored and issues a token again.
  Future<void> _arm(
    String token,
    List<String>? bankIds, {
    List<String>? senders,
  }) async {
    await _storage.setInt(
      _catchUpKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    try {
      await _capture.configure(
        ingestToken: token,
        senders: senders ?? await _sendersFor(bankIds ?? const []),
      );
    } on PlatformException catch (e) {
      AppLogger.warning('Bank capture not armed (${e.code}): ${e.message}');
    }
  }

  Future<void> _standDown() async {
    await _capture.clear();
    await _storage.remove(_catchUpKey);
  }

  /// SMS the live receiver didn't see — the app was force-stopped, or the
  /// phone hadn't been unlocked yet after a reboot — go up through the batch
  /// endpoint as `android_sms`, which behaves exactly like live delivery
  /// (automatic mode applies, duplicates are dropped). Returns how many the
  /// server stored.
  Future<int> _catchUp(List<String> senders) async {
    if (_deviceMethod != BankLinkMethod.sms) return 0;
    final mark = _storage.getInt(_catchUpKey);
    final now = DateTime.now();
    if (mark == null) {
      // Capture armed by an older build: start from here, never from the
      // past the user didn't ask to scan.
      await _storage.setInt(_catchUpKey, now.millisecondsSinceEpoch);
      return 0;
    }
    final since = DateTime.fromMillisecondsSinceEpoch(mark)
        .subtract(_catchUpOverlap);
    final sms = await _capture.readInbox(since: since, senders: senders);
    if (sms.isEmpty) {
      await _storage.setInt(_catchUpKey, now.millisecondsSinceEpoch);
      return 0;
    }
    var created = 0;
    for (final chunk in SmsBatchChunker.chunk(_wire(sms))) {
      created += (await _uploadWithRetry(chunk, channel: 'android_sms')).created;
    }
    await _storage.setInt(_catchUpKey, now.millisecondsSinceEpoch);
    return created;
  }

  static List<Map<String, dynamic>> _wire(List<RawSms> sms) => [
        for (final message in sms)
          if (message.body.trim().isNotEmpty) message.toWire(),
      ];

  /// Linked banks' sender ids as shown on phones (the iPhone intent offers
  /// them by name; Android lower-cases them for its exact match).
  Future<List<String>> _sendersFor(List<String> bankIds) async {
    if (_banks.isEmpty) _banks = await _remote.getBanks();
    final seen = <String>{};
    return [
      for (final bank in _banks)
        if (bankIds.contains(bank.id))
          for (final sender in bank.senderIds)
            if (seen.add(sender.trim().toLowerCase())) sender.trim(),
    ];
  }

  /// A chunk keeps one key and one encoded body for every attempt, so a
  /// retry after a timeout is replayed, never stored twice. While the
  /// server is still working on the first attempt it answers
  /// `IDEMPOTENCY_IN_PROGRESS`; that is waited out, not treated as a
  /// failure.
  Future<BatchUpload> _uploadWithRetry(
    List<Map<String, dynamic>> messages, {
    required String channel,
  }) async {
    final key = BankSyncRemoteDataSource.newIdempotencyKey();
    final body = jsonEncode({'channel': channel, 'messages': messages});
    for (var attempt = 1;; attempt++) {
      try {
        return await _remote.uploadBatch(
          encodedBody: body,
          idempotencyKey: key,
        );
      } on DioException catch (e) {
        final api = ApiError.fromDio(e);
        final inProgress = api?.code == 'IDEMPOTENCY_IN_PROGRESS';
        final retryable = inProgress ||
            ApiError.isConnectionProblem(e) ||
            (api?.status ?? 0) >= 500;
        if (!retryable || attempt == 3) rethrow;
        await Future<void>.delayed(
          api?.retryAfter ?? Duration(seconds: 2 * attempt),
        );
      }
    }
  }

  static Iterable<List<String>> _chunks(List<String> ids) sync* {
    final unique = ids.toSet().toList();
    for (var i = 0; i < unique.length; i += _idsPerCall) {
      yield unique.sublist(
        i,
        i + _idsPerCall > unique.length ? unique.length : i + _idsPerCall,
      );
    }
  }
}

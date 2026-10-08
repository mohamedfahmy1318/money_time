import 'dart:async';

import 'package:flutter/services.dart';

import 'package:mony_time/src/config/api/api_session.dart';
import 'package:mony_time/src/config/app_config.dart';
import 'package:mony_time/src/features/bank_sync/data/models/raw_sms.dart';
import 'package:mony_time/src/utils/logger.dart';

/// What the native capture currently holds.
class CaptureStatus {
  const CaptureStatus({
    this.configured = false,
    this.queued = 0,
    this.needsToken = false,
  });

  factory CaptureStatus.fromMap(Map<Object?, Object?> map) => CaptureStatus(
        configured: map['configured'] == true,
        queued: (map['queued'] as num?)?.toInt() ?? 0,
        needsToken: map['needsToken'] == true,
      );

  /// An ingest token is stored on the device.
  final bool configured;

  /// SMS captured but not delivered yet (Android).
  final int queued;

  /// The server rejected the stored token (revoked elsewhere): re-issue it.
  final bool needsToken;
}

/// Bridge to the native bank-SMS capture (`money_time/bank_capture`).
///
/// * **Android** — a `RECEIVE_SMS` receiver filters the linked banks'
///   senders and queues each SMS for a WorkManager job that posts it to
///   `/bank-sync/ingest` with the ingest token, even with the app killed.
///   [readInbox] reads the last days for the 30-day scan (`READ_SMS`).
/// * **iPhone** — apps can't read SMS; a Shortcuts automation runs the
///   "Log Bank Message" App Intent, which posts with the same token. The
///   token and sender list are stored in the Keychain / app defaults here.
///
/// The ingest token never lives in Dart storage: it goes straight to the
/// platform's Keystore / Keychain, readable by the background code only.
class BankCaptureLocalDataSource {
  BankCaptureLocalDataSource({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('money_time/bank_capture') {
    _channel.setMethodCallHandler(_onNativeCall);
  }

  final MethodChannel _channel;
  final StreamController<void> _captured = StreamController<void>.broadcast();

  /// Native delivered new messages while the app is running.
  Stream<void> get captured => _captured.stream;

  /// Arms capture with a fresh ingest token and the linked banks' sender ids.
  Future<void> configure({
    required String ingestToken,
    required List<String> senders,
  }) {
    final session = ApiSession.instance;
    // The app version is read natively at request time; only the language
    // travels with the config (and follows the UI through [updateSenders]).
    return _invoke('configure', {
      'baseUrl': AppConfig.baseUrl,
      'ingestToken': ingestToken,
      'senders': senders,
      'deviceId': session.deviceId,
      'language': session.language,
    });
  }

  /// Refreshes the sender filter and the UI language without a new token.
  Future<void> updateSenders(List<String> senders) => _invoke('updateSenders', {
        'senders': senders,
        'language': ApiSession.instance.language,
      });

  /// Forgets the token, the sender filter and anything queued.
  Future<void> clear() => _invoke('clear');

  /// Retries queued deliveries now (after a fresh token, on app open).
  Future<void> flush() => _invoke('flush');

  Future<CaptureStatus> status() async {
    final result = await _invoke<Map<Object?, Object?>>('status');
    return result == null
        ? const CaptureStatus()
        : CaptureStatus.fromMap(result);
  }

  /// Bank SMS in the device inbox since [since] from [senders] (trimmed,
  /// case-insensitive exact match). Android only; empty elsewhere.
  Future<List<RawSms>> readInbox({
    required DateTime since,
    required List<String> senders,
  }) async {
    final List<Object?>? result;
    try {
      result = await _invoke<List<Object?>>('readInbox', {
        'sinceMs': since.millisecondsSinceEpoch,
        'senders': senders,
      });
    } on PlatformException catch (e) {
      // READ_SMS revoked since the wizard: nothing to scan, not an error.
      if (e.code == 'PERMISSION_DENIED') return const [];
      rethrow;
    }
    return [
      for (final row in result ?? const <Object?>[])
        if (row is Map) RawSms.fromMap(row),
    ];
  }

  /// `onCaptured`: new messages reached the server. `onNeedsToken`: the
  /// token was revoked — the refresh this triggers re-issues it.
  Future<void> _onNativeCall(MethodCall call) async {
    if (call.method == 'onCaptured' || call.method == 'onNeedsToken') {
      _captured.add(null);
    }
  }

  /// Platforms without the native side (tests, desktop) behave as "nothing
  /// to capture" instead of failing the flow.
  Future<T?> _invoke<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      AppLogger.warning('Bank capture unavailable on this platform: $method');
      return null;
    }
  }
}

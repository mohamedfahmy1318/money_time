import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mony_time/src/utils/failure.dart';
import 'package:mony_time/src/utils/logger.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_link.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_sync_results.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_sync_summary.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/connect_bank_link_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/disconnect_bank_link_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/ensure_bank_capture_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/get_bank_categories_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/get_bank_link_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/get_bank_messages_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/get_bank_summary_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/get_supported_banks_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/import_bank_message_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/import_bank_messages_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/import_recent_sms_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/reissue_bank_capture_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/set_bank_message_status_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/stop_bank_capture_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/submit_bank_message_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/update_bank_link_usecase.dart';
import 'package:mony_time/src/shared/enums/transaction_type.dart';

enum BankSyncStatus { initial, loading, ready, failure }

/// One-shot outcome of the latest mutation, listened to by the screen that
/// triggered it.
enum BankSyncAction {
  idle,
  working,
  connected,
  scanned,
  disconnected,
  linkUpdated,
  captureMoved,
  submitted,
  statusChanged,
  imported,
  refreshFailed,
  failure,
}

class BankSyncState extends Equatable {
  const BankSyncState({
    this.status = BankSyncStatus.initial,
    this.banks = const [],
    this.link = BankLink.disconnected,
    this.summary = BankSyncSummary.empty,
    this.pending = const [],
    this.imported = BankMessagePage.empty,
    this.ignored = BankMessagePage.empty,
    this.loadingMore = const {},
    this.categories = const {},
    this.deviceMethod = BankLinkMethod.sms,
    this.isScanning = false,
    this.captureRevoked = false,
    this.action = BankSyncAction.idle,
    this.lastImport,
    this.lastSubmitted,
    this.lastScan,
    this.lastMoved = const [],
    this.errorMessage,
    this.errorCode,
  });

  final BankSyncStatus status;
  final List<Bank> banks;
  final BankLink link;
  final BankSyncSummary summary;

  /// Every pending message (the tab is loaded completely so bulk add and the
  /// money in/out totals are exact).
  final List<BankMessage> pending;

  /// Loaded pages of the settled tabs (infinite scroll).
  final BankMessagePage imported;
  final BankMessagePage ignored;
  final Set<BankMessageStatus> loadingMore;

  /// Picker categories, loaded on demand per type.
  final Map<TransactionType, List<BankCategory>> categories;

  /// How this device captures: SMS (Android) or Shortcuts (iPhone).
  final BankLinkMethod deviceMethod;
  final bool isScanning;

  /// This phone's ingest token was revoked (another phone of the same
  /// platform took over, or the password changed): capture is paused here
  /// until the user claims it back with [BankSyncCubit.useThisPhone].
  final bool captureRevoked;

  final BankSyncAction action;

  /// Results of the latest import / paste / scan / ignore, read by the
  /// listener that fired them (toasts, mirroring transactions into the
  /// ledger).
  final BulkImportResult? lastImport;
  final SubmittedBankMessage? lastSubmitted;
  final HistoryScanResult? lastScan;
  final List<BankMessage> lastMoved;
  final String? errorMessage;
  final String? errorCode;

  bool get isLoading => status == BankSyncStatus.loading;
  bool get isWorking => action == BankSyncAction.working;
  bool get isConnected => link.isConnected;

  /// The link captures on this device (not on a phone of the other
  /// platform).
  bool get capturesHere => link.isConnected && link.method == deviceMethod;

  /// Anything to show besides a loading / error placeholder.
  bool get hasContent =>
      link.isConnected ||
      pending.isNotEmpty ||
      imported.items.isNotEmpty ||
      ignored.items.isNotEmpty;

  /// Pending messages safe to add without a second look.
  List<BankMessage> get pendingConfident =>
      pending.where((m) => m.isTransaction && !m.needsAttention).toList();

  List<Bank> get linkedBanks =>
      banks.where((b) => link.bankIds.contains(b.id)).toList();

  Bank? bankById(String? id) {
    for (final b in banks) {
      if (b.id == id) return b;
    }
    return null;
  }

  BankMessage? messageById(String id) {
    for (final list in [pending, imported.items, ignored.items]) {
      for (final m in list) {
        if (m.id == id) return m;
      }
    }
    return null;
  }

  BankSyncState copyWith({
    BankSyncStatus? status,
    List<Bank>? banks,
    BankLink? link,
    BankSyncSummary? summary,
    List<BankMessage>? pending,
    BankMessagePage? imported,
    BankMessagePage? ignored,
    Set<BankMessageStatus>? loadingMore,
    Map<TransactionType, List<BankCategory>>? categories,
    bool? isScanning,
    bool? captureRevoked,
    BankSyncAction? action,
    BulkImportResult? lastImport,
    SubmittedBankMessage? lastSubmitted,
    HistoryScanResult? lastScan,
    List<BankMessage>? lastMoved,
    String? errorMessage,
    String? errorCode,
  }) {
    return BankSyncState(
      status: status ?? this.status,
      banks: banks ?? this.banks,
      link: link ?? this.link,
      summary: summary ?? this.summary,
      pending: pending ?? this.pending,
      imported: imported ?? this.imported,
      ignored: ignored ?? this.ignored,
      loadingMore: loadingMore ?? this.loadingMore,
      categories: categories ?? this.categories,
      deviceMethod: deviceMethod,
      isScanning: isScanning ?? this.isScanning,
      captureRevoked: captureRevoked ?? this.captureRevoked,
      action: action ?? this.action,
      lastImport: lastImport ?? this.lastImport,
      lastSubmitted: lastSubmitted ?? this.lastSubmitted,
      lastScan: lastScan ?? this.lastScan,
      lastMoved: lastMoved ?? this.lastMoved,
      errorMessage: errorMessage,
      errorCode: errorCode,
    );
  }

  @override
  List<Object?> get props => [
        status,
        banks,
        link,
        summary,
        pending,
        imported,
        ignored,
        loadingMore,
        categories,
        deviceMethod,
        isScanning,
        captureRevoked,
        action,
        lastImport,
        lastSubmitted,
        lastScan,
        lastMoved,
        errorMessage,
        errorCode,
      ];
}

typedef _Inbox = ({
  BankSyncSummary summary,
  List<BankMessage> pending,
  BankMessagePage imported,
  BankMessagePage ignored,
});

/// App-wide cubit for the bank-SMS link and its review inbox — registered in
/// `StateWrapper` so the link hub, the inbox, the home banner and the profile
/// row share one source of truth. `SessionListenerWrapper` reloads it on
/// sign-in and resets it on sign-out.
///
/// No navigation or toasts here — it only emits state.
///
/// Reads and writes overlap freely (a resume refresh while the user taps
/// Ignore, a sign-out while a load is in flight), so every read captures
/// [_epoch] before awaiting and drops its result when something newer —
/// a mutation, a full load, a sign-out — moved it meanwhile. Mutations
/// apply their own result unless the user signed out in between.
class BankSyncCubit extends Cubit<BankSyncState> {
  BankSyncCubit({
    required GetSupportedBanksUseCase getBanks,
    required GetBankLinkUseCase getLink,
    required ConnectBankLinkUseCase connect,
    required UpdateBankLinkUseCase updateLink,
    required DisconnectBankLinkUseCase disconnect,
    required GetBankSummaryUseCase getSummary,
    required GetBankMessagesUseCase getMessages,
    required SubmitBankMessageUseCase submit,
    required SetBankMessageStatusUseCase setStatus,
    required ImportBankMessageUseCase importOne,
    required ImportBankMessagesUseCase importMany,
    required GetBankCategoriesUseCase getCategories,
    required ImportRecentSmsUseCase importRecent,
    required EnsureBankCaptureUseCase ensureCapture,
    required ReissueBankCaptureUseCase reissueCapture,
    required StopBankCaptureUseCase stopCapture,
    required bool Function() hasSession,
    required BankLinkMethod deviceMethod,
    required Stream<void> capturedMessages,
  })  : _getBanks = getBanks,
        _getLink = getLink,
        _connect = connect,
        _updateLink = updateLink,
        _disconnect = disconnect,
        _getSummary = getSummary,
        _getMessages = getMessages,
        _submit = submit,
        _setStatus = setStatus,
        _importOne = importOne,
        _importMany = importMany,
        _getCategories = getCategories,
        _importRecent = importRecent,
        _ensureCapture = ensureCapture,
        _reissueCapture = reissueCapture,
        _stopCapture = stopCapture,
        _hasSession = hasSession,
        super(BankSyncState(deviceMethod: deviceMethod)) {
    // Background capture delivered (or lost its token) while we're open.
    // Loading itself is driven by the session (`SessionListenerWrapper`).
    _captured = capturedMessages.listen((_) => refresh());
  }

  final GetSupportedBanksUseCase _getBanks;
  final GetBankLinkUseCase _getLink;
  final ConnectBankLinkUseCase _connect;
  final UpdateBankLinkUseCase _updateLink;
  final DisconnectBankLinkUseCase _disconnect;
  final GetBankSummaryUseCase _getSummary;
  final GetBankMessagesUseCase _getMessages;
  final SubmitBankMessageUseCase _submit;
  final SetBankMessageStatusUseCase _setStatus;
  final ImportBankMessageUseCase _importOne;
  final ImportBankMessagesUseCase _importMany;
  final GetBankCategoriesUseCase _getCategories;
  final ImportRecentSmsUseCase _importRecent;
  final EnsureBankCaptureUseCase _ensureCapture;
  final ReissueBankCaptureUseCase _reissueCapture;
  final StopBankCaptureUseCase _stopCapture;
  final bool Function() _hasSession;
  late final StreamSubscription<void> _captured;

  /// Bumped by every mutation, full load and sign-out; see the class note.
  int _epoch = 0;

  static const _settledPageSize = 50;
  static const _pendingPageSize = 200;

  /// Pending is paged through completely, up to this many pages.
  static const _maxPendingPages = 10;

  // ── Loading ────────────────────────────────────────────────────────────────

  /// Full load: catalog for everyone; link, counters and inbox when signed in.
  /// [quiet] keeps what's on screen while it runs (a retry on resume) instead
  /// of showing the loading state.
  Future<void> load({bool quiet = false}) async {
    final epoch = ++_epoch;
    if (!quiet && state.status != BankSyncStatus.ready) {
      emit(state.copyWith(status: BankSyncStatus.loading));
    }

    final banks = await _getBanks();
    if (isClosed || epoch != _epoch) return;
    if (!_hasSession()) {
      banks.fold(
        (failure) => emit(state.copyWith(
          status: BankSyncStatus.failure,
          errorMessage: failure.message,
          errorCode: failure.code,
        )),
        (list) => emit(BankSyncState(
          status: BankSyncStatus.ready,
          banks: list,
          deviceMethod: state.deviceMethod,
        )),
      );
      return;
    }

    final (link, inbox) = await (_getLink(), _fetchInbox()).wait;
    if (_stale(epoch)) return;
    banks.flatMap((b) => link.flatMap((l) => inbox.map((i) => (b, l, i)))).fold(
      (failure) => emit(state.copyWith(
        status: BankSyncStatus.failure,
        errorMessage: failure.message,
        errorCode: failure.code,
      )),
      (data) {
        final (bankList, linkValue, inboxValue) = data;
        emit(_withInbox(
          state.copyWith(
            status: BankSyncStatus.ready,
            banks: bankList,
            link: linkValue,
          ),
          inboxValue,
        ));
        _armCapture(linkValue);
      },
    );
  }

  /// Quiet reload of link + inbox (pull to refresh, capture events, after
  /// mutations). Keeps what's on screen when it fails and says so through
  /// [BankSyncAction.refreshFailed].
  Future<void> refresh() async {
    if (!_hasSession()) return;
    if (state.status != BankSyncStatus.ready) return load(quiet: true);

    final epoch = _epoch;
    final (link, inbox) = await (_getLink(), _fetchInbox()).wait;
    if (_stale(epoch)) return;
    link.flatMap((l) => inbox.map((i) => (l, i))).fold(
      (failure) {
        AppLogger.warning('Bank inbox refresh failed: $failure');
        emit(state.copyWith(
          action: BankSyncAction.refreshFailed,
          errorMessage: failure.message,
          errorCode: failure.code,
        ));
      },
      (data) {
        emit(_withInbox(state.copyWith(link: data.$1), data.$2));
        _armCapture(data.$1);
      },
    );
  }

  Future<void> loadMore(BankMessageStatus status) async {
    final page = _settled(status);
    if (status == BankMessageStatus.pending ||
        !page.hasMore ||
        state.loadingMore.contains(status)) {
      return;
    }
    emit(state.copyWith(loadingMore: {...state.loadingMore, status}));

    final epoch = _epoch;
    final result = await _getMessages(
      status: status,
      cursor: page.nextCursor,
      limit: _settledPageSize,
    );
    if (isClosed) return;
    final loading = {...state.loadingMore}..remove(status);
    if (_stale(epoch)) return emit(state.copyWith(loadingMore: loading));
    result.fold(
      (failure) => emit(state.copyWith(loadingMore: loading)),
      (next) {
        // Merge into the tab as it is now, not as it was when the request
        // left: a message added to it meanwhile stays.
        final current = _settled(status);
        final seen = {for (final m in current.items) m.id};
        final merged = BankMessagePage(
          items: [
            ...current.items,
            for (final m in next.items)
              if (seen.add(m.id)) m,
          ],
          nextCursor: next.nextCursor,
          hasMore: next.hasMore,
        );
        emit(status == BankMessageStatus.imported
            ? state.copyWith(imported: merged, loadingMore: loading)
            : state.copyWith(ignored: merged, loadingMore: loading));
      },
    );
  }

  Future<void> loadCategories(TransactionType type) async {
    if (state.categories.containsKey(type)) return;
    final result = await _getCategories(type);
    if (_signedOut) return;
    result.fold(
      (failure) => AppLogger.warning('Categories failed: $failure'),
      (list) => emit(state.copyWith(
        categories: {...state.categories, type: list},
      )),
    );
  }

  // ── Link ───────────────────────────────────────────────────────────────────

  Future<void> connect({
    required List<String> bankIds,
    required ImportMode mode,
  }) async {
    _epoch++;
    emit(state.copyWith(action: BankSyncAction.working));

    final result = await _connect(bankIds: bankIds, mode: mode);
    if (_signedOut) return;

    await result.fold(_emitFailure, (link) async {
      emit(state.copyWith(
        link: link,
        captureRevoked: false,
        action: BankSyncAction.connected,
      ));
      await refresh();
    });
  }

  /// The wizard's 30-day import (Android, after connect).
  Future<void> scanHistory() async {
    _epoch++;
    emit(state.copyWith(action: BankSyncAction.working, isScanning: true));

    final result = await _importRecent(bankIds: state.link.bankIds);
    if (_signedOut) return;

    await result.fold(
      (failure) async {
        emit(state.copyWith(isScanning: false));
        _emitFailure(failure);
      },
      (scan) async {
        await refresh();
        if (_signedOut) return;
        emit(state.copyWith(
          isScanning: false,
          lastScan: scan,
          action: BankSyncAction.scanned,
        ));
      },
    );
  }

  Future<void> setMode(ImportMode mode) =>
      _saveLink(state.link.copyWith(mode: mode));

  Future<void> toggleBank(String bankId) {
    final ids = List.of(state.link.bankIds);
    if (!ids.remove(bankId)) ids.add(bankId);
    return _saveLink(state.link.copyWith(bankIds: ids));
  }

  Future<void> disconnect() async {
    _epoch++;
    emit(state.copyWith(action: BankSyncAction.working));

    final result = await _disconnect();
    if (_signedOut) return;

    result.fold(
      _emitFailure,
      (_) => emit(state.copyWith(
        link: BankLink.disconnected,
        captureRevoked: false,
        summary: BankSyncSummary(
          pendingCount: state.summary.pendingCount,
          pendingNeedsCheckCount: state.summary.pendingNeedsCheckCount,
          importedCount: state.summary.importedCount,
          ignoredCount: state.summary.ignoredCount,
          lastMessageAt: state.summary.lastMessageAt,
        ),
        action: BankSyncAction.disconnected,
      )),
    );
  }

  /// "Capture on this phone": takes the ingest token over from the other
  /// phone of this platform.
  Future<void> useThisPhone() async {
    _epoch++;
    emit(state.copyWith(action: BankSyncAction.working));

    final result = await _reissueCapture();
    if (_signedOut) return;

    result.fold(
      _emitFailure,
      (_) => emit(state.copyWith(
        captureRevoked: false,
        action: BankSyncAction.captureMoved,
      )),
    );
  }

  /// Sign-out: forget the user's inbox and disarm capture on this device.
  /// The reset comes first so nothing in flight lands on the guest state;
  /// the guest intro still needs the catalog, fetched again if a load was
  /// cut short.
  Future<void> signOut() async {
    _epoch++;
    emit(BankSyncState(
      status: BankSyncStatus.ready,
      banks: state.banks,
      deviceMethod: state.deviceMethod,
    ));
    await _stopCapture();
    if (!isClosed && state.banks.isEmpty) await load(quiet: true);
  }

  // ── Messages ───────────────────────────────────────────────────────────────

  /// Stores a pasted SMS.
  Future<void> submit({required String sender, required String body}) async {
    _epoch++;
    emit(state.copyWith(action: BankSyncAction.working));

    final result = await _submit(sender: sender, body: body);
    if (_signedOut) return;

    await result.fold(_emitFailure, (submitted) async {
      emit(_place(state, submitted.message).copyWith(
        lastSubmitted: submitted,
        action: BankSyncAction.submitted,
      ));
      await _refreshSummary();
    });
  }

  Future<void> ignore(String id) =>
      _changeStatus(id, BankMessageStatus.ignored);

  Future<void> restore(String id) =>
      _changeStatus(id, BankMessageStatus.pending);

  /// Adds one message as a transaction, with the review screen's edits.
  Future<void> importOne(
    String id, {
    ImportOverrides overrides = ImportOverrides.none,
  }) async {
    _epoch++;
    emit(state.copyWith(action: BankSyncAction.working));

    final result = await _importOne(id, overrides: overrides);
    if (_signedOut) return;

    await result.fold(
      (failure) async {
        _emitFailure(failure);
        // CONFLICT: added or ignored elsewhere — show the real state.
        if (failure.code == 'CONFLICT') await refresh();
      },
      (imported) async {
        emit(_place(state, imported.message).copyWith(
          lastImport: BulkImportResult(imported: [imported]),
          action: BankSyncAction.imported,
        ));
        await _refreshSummary();
      },
    );
  }

  /// "Add N clear messages" — parsed values only.
  Future<void> importMany(List<String> ids) async {
    if (ids.isEmpty) return;
    _epoch++;
    emit(state.copyWith(action: BankSyncAction.working));

    final result = await _importMany(ids);
    if (_signedOut) return;

    await result.fold(_emitFailure, (bulk) async {
      var next = state;
      for (final item in bulk.imported) {
        next = _place(next, item.message);
      }
      emit(next.copyWith(lastImport: bulk, action: BankSyncAction.imported));
      // Skipped ones changed elsewhere; reload so the tabs tell the truth.
      bulk.skipped.isEmpty ? await _refreshSummary() : await refresh();
    });
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  /// A read started at [epoch] has been overtaken (or the user left).
  bool _stale(int epoch) => _signedOut || epoch != _epoch;

  bool get _signedOut => isClosed || !_hasSession();

  BankMessagePage _settled(BankMessageStatus status) =>
      status == BankMessageStatus.imported ? state.imported : state.ignored;

  Future<Either<Failure, _Inbox>> _fetchInbox() async {
    final (summary, pending, imported, ignored) = await (
      _getSummary(),
      _allPending(),
      _getMessages(status: BankMessageStatus.imported, limit: _settledPageSize),
      _getMessages(status: BankMessageStatus.ignored, limit: _settledPageSize),
    ).wait;
    return summary.flatMap((s) => pending.flatMap((p) => imported.flatMap(
          (i) => ignored.map((g) => (
                summary: s,
                pending: p,
                imported: i,
                ignored: g,
              )),
        )));
  }

  Future<Either<Failure, List<BankMessage>>> _allPending() async {
    final all = <BankMessage>[];
    String? cursor;
    for (var page = 0; page < _maxPendingPages; page++) {
      final result = await _getMessages(
        status: BankMessageStatus.pending,
        cursor: cursor,
        limit: _pendingPageSize,
      );
      final failure = result.fold<Failure?>((f) => f, (p) {
        all.addAll(p.items);
        cursor = p.hasMore ? p.nextCursor : null;
        return null;
      });
      if (failure != null) return left(failure);
      if (cursor == null) break;
    }
    return right(all);
  }

  BankSyncState _withInbox(BankSyncState base, _Inbox inbox) => base.copyWith(
        summary: inbox.summary,
        pending: inbox.pending,
        imported: inbox.imported,
        ignored: inbox.ignored,
      );

  /// Moves [message] into the list of its status (dropping it from the
  /// others), newest first.
  static BankSyncState _place(BankSyncState s, BankMessage message) {
    List<BankMessage> without(List<BankMessage> list) =>
        list.where((m) => m.id != message.id).toList();
    List<BankMessage> withIt(List<BankMessage> list) => [
          ...without(list),
          message
        ]..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

    final pending = message.status == BankMessageStatus.pending
        ? withIt(s.pending)
        : without(s.pending);
    final imported = message.status == BankMessageStatus.imported
        ? withIt(s.imported.items)
        : without(s.imported.items);
    final ignored = message.status == BankMessageStatus.ignored
        ? withIt(s.ignored.items)
        : without(s.ignored.items);

    return s.copyWith(
      pending: pending,
      imported: BankMessagePage(
        items: imported,
        nextCursor: s.imported.nextCursor,
        hasMore: s.imported.hasMore,
      ),
      ignored: BankMessagePage(
        items: ignored,
        nextCursor: s.ignored.nextCursor,
        hasMore: s.ignored.hasMore,
      ),
    );
  }

  Future<void> _changeStatus(String id, BankMessageStatus to) async {
    final message = state.messageById(id);
    if (message == null) return;
    _epoch++;
    // Optimistic: the row moves tabs immediately, the server catches up.
    emit(_place(state, message.copyWith(status: to)).copyWith(
      action: BankSyncAction.working,
    ));

    final result = await _setStatus([id], to);
    if (_signedOut) return;

    await result.fold(
      // Only this row goes back; anything else that changed meanwhile stays.
      (failure) async => emit(_place(state, message).copyWith(
        action: BankSyncAction.failure,
        errorMessage: failure.message,
        errorCode: failure.code,
      )),
      (moved) async {
        var next = state;
        for (final m in moved) {
          next = _place(next, m);
        }
        emit(next.copyWith(
          action: BankSyncAction.statusChanged,
          lastMoved: moved,
        ));
        // Nothing moved: it changed on another device — resync.
        moved.isEmpty ? await refresh() : await _refreshSummary();
      },
    );
  }

  Future<void> _saveLink(BankLink link) async {
    final previous = state.link;
    _epoch++;
    emit(state.copyWith(action: BankSyncAction.working, link: link));

    final result = await _updateLink(bankIds: link.bankIds, mode: link.mode);
    if (_signedOut) return;

    result.fold(
      (failure) => emit(state.copyWith(
        action: BankSyncAction.failure,
        link: previous,
        errorMessage: failure.message,
        errorCode: failure.code,
      )),
      (stored) => emit(state.copyWith(
        action: BankSyncAction.linkUpdated,
        link: stored,
      )),
    );
  }

  Future<void> _refreshSummary() async {
    final epoch = _epoch;
    final result = await _getSummary();
    if (_stale(epoch)) return;
    result.fold(
      (failure) => AppLogger.warning('Bank summary failed: $failure'),
      (summary) => emit(state.copyWith(summary: summary)),
    );
  }

  /// Fire-and-forget: capture problems never block the inbox. Records
  /// whether this phone's token was revoked, and reloads when the catch-up
  /// scan delivered SMS the receiver had missed.
  void _armCapture(BankLink link) {
    _ensureCapture(link).then((result) {
      if (_signedOut) return;
      result.fold(
        (failure) => AppLogger.warning('Bank capture not armed: $failure'),
        (report) {
          final revoked = report.outcome == CaptureOutcome.revoked;
          if (revoked != state.captureRevoked) {
            emit(state.copyWith(captureRevoked: revoked));
          }
          if (report.caughtUp > 0) refresh();
        },
      );
    });
  }

  Future<void> _emitFailure(Failure failure) async => emit(state.copyWith(
        action: BankSyncAction.failure,
        errorMessage: failure.message,
        errorCode: failure.code,
      ));

  @override
  Future<void> close() {
    _captured.cancel();
    return super.close();
  }
}

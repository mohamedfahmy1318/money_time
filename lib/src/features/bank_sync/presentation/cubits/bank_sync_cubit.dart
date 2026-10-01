import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mony_time/src/utils/failure.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_link.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/connect_bank_link_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/disconnect_bank_link_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/get_bank_link_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/get_bank_messages_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/get_supported_banks_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/ingest_bank_message_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/set_bank_message_status_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/update_bank_link_usecase.dart';

enum BankSyncStatus { initial, loading, ready, failure }

/// One-shot outcome of the latest mutation, listened to by the screen that
/// triggered it.
enum BankSyncAction {
  idle,
  working,
  connected,
  disconnected,
  linkUpdated,
  ingested,
  statusChanged,
  failure,
}

class BankSyncState extends Equatable {
  const BankSyncState({
    this.status = BankSyncStatus.initial,
    this.banks = const [],
    this.link = BankLink.disconnected,
    this.messages = const [],
    this.action = BankSyncAction.idle,
    this.lastIngested,
    this.errorMessage,
  });

  final BankSyncStatus status;
  final List<Bank> banks;
  final BankLink link;

  /// Every received message, newest first.
  final List<BankMessage> messages;

  final BankSyncAction action;

  /// The message stored by the latest [BankSyncCubit.ingest].
  final BankMessage? lastIngested;
  final String? errorMessage;

  bool get isLoading => status == BankSyncStatus.loading;
  bool get isWorking => action == BankSyncAction.working;
  bool get isConnected => link.isConnected;

  List<BankMessage> get pending => _where(BankMessageStatus.pending);
  List<BankMessage> get imported => _where(BankMessageStatus.imported);
  List<BankMessage> get ignored => _where(BankMessageStatus.ignored);

  /// Pending messages safe to import without a second look.
  List<BankMessage> get pendingConfident =>
      pending.where((m) => !m.needsAttention).toList();

  List<Bank> get linkedBanks =>
      banks.where((b) => link.bankIds.contains(b.id)).toList();

  Bank? bankById(String id) {
    for (final b in banks) {
      if (b.id == id) return b;
    }
    return null;
  }

  BankMessage? messageById(String id) {
    for (final m in messages) {
      if (m.id == id) return m;
    }
    return null;
  }

  List<BankMessage> _where(BankMessageStatus s) =>
      messages.where((m) => m.status == s).toList();

  BankSyncState copyWith({
    BankSyncStatus? status,
    List<Bank>? banks,
    BankLink? link,
    List<BankMessage>? messages,
    BankSyncAction? action,
    BankMessage? lastIngested,
    String? errorMessage,
  }) {
    return BankSyncState(
      status: status ?? this.status,
      banks: banks ?? this.banks,
      link: link ?? this.link,
      messages: messages ?? this.messages,
      action: action ?? this.action,
      lastIngested: lastIngested ?? this.lastIngested,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, banks, link, messages, action, lastIngested, errorMessage];
}

/// App-wide cubit for the bank-SMS link and its review inbox — registered in
/// `StateWrapper` so the link hub, the inbox, the home banner and the profile
/// row share one source of truth.
///
/// Turning a message into a transaction goes through `TransactionsCubit`
/// (owned by the screen, see `BankImportFlow`); this cubit only records the
/// message's new status.
class BankSyncCubit extends Cubit<BankSyncState> {
  BankSyncCubit({
    required GetSupportedBanksUseCase getBanks,
    required GetBankLinkUseCase getLink,
    required ConnectBankLinkUseCase connect,
    required UpdateBankLinkUseCase updateLink,
    required DisconnectBankLinkUseCase disconnect,
    required GetBankMessagesUseCase getMessages,
    required IngestBankMessageUseCase ingest,
    required SetBankMessageStatusUseCase setStatus,
  })  : _getBanks = getBanks,
        _getLink = getLink,
        _connect = connect,
        _updateLink = updateLink,
        _disconnect = disconnect,
        _getMessages = getMessages,
        _ingest = ingest,
        _setStatus = setStatus,
        super(const BankSyncState()) {
    load();
  }

  final GetSupportedBanksUseCase _getBanks;
  final GetBankLinkUseCase _getLink;
  final ConnectBankLinkUseCase _connect;
  final UpdateBankLinkUseCase _updateLink;
  final DisconnectBankLinkUseCase _disconnect;
  final GetBankMessagesUseCase _getMessages;
  final IngestBankMessageUseCase _ingest;
  final SetBankMessageStatusUseCase _setStatus;

  Future<void> load() async {
    emit(state.copyWith(status: BankSyncStatus.loading));

    final banks = await _getBanks();
    final link = await _getLink();
    final messages = await _getMessages();

    banks
        .flatMap((b) => link.flatMap((l) => messages.map((m) => (b, l, m))))
        .fold(
          (failure) => emit(state.copyWith(
            status: BankSyncStatus.failure,
            errorMessage: failure.message,
          )),
          (data) => emit(state.copyWith(
            status: BankSyncStatus.ready,
            banks: data.$1,
            link: data.$2,
            messages: _sorted(data.$3),
          )),
        );
  }

  Future<void> connect({
    required BankLinkMethod method,
    required List<String> bankIds,
    required ImportMode mode,
  }) async {
    emit(state.copyWith(action: BankSyncAction.working));

    final linked = await _connect(method: method, bankIds: bankIds, mode: mode);
    // Connecting pulls in recent alerts, so refresh the inbox with it.
    final messages = await _getMessages();

    linked.flatMap((l) => messages.map((m) => (l, m))).fold(
          _emitFailure,
          (data) => emit(state.copyWith(
            action: BankSyncAction.connected,
            link: data.$1,
            messages: _sorted(data.$2),
          )),
        );
  }

  Future<void> disconnect() async {
    emit(state.copyWith(action: BankSyncAction.working));

    final result = await _disconnect();

    result.fold(
      _emitFailure,
      (_) => emit(state.copyWith(
        action: BankSyncAction.disconnected,
        link: BankLink.disconnected,
      )),
    );
  }

  Future<void> setMode(ImportMode mode) => _saveLink(state.link.copyWith(mode: mode));

  Future<void> toggleBank(String bankId) {
    final ids = List.of(state.link.bankIds);
    if (!ids.remove(bankId)) ids.add(bankId);
    return _saveLink(state.link.copyWith(bankIds: ids));
  }

  /// Stores a message pasted or forwarded into the app.
  Future<void> ingest({required String sender, required String body}) async {
    emit(state.copyWith(action: BankSyncAction.working));

    final result = await _ingest(sender: sender, body: body);

    result.fold(
      _emitFailure,
      (message) => emit(state.copyWith(
        action: BankSyncAction.ingested,
        lastIngested: message,
        messages: _sorted([...state.messages, message]),
      )),
    );
  }

  Future<void> markImported(List<String> ids) =>
      _changeStatus(ids, BankMessageStatus.imported);

  Future<void> ignore(String id) =>
      _changeStatus([id], BankMessageStatus.ignored);

  Future<void> restore(String id) =>
      _changeStatus([id], BankMessageStatus.pending);

  Future<void> _changeStatus(
    List<String> ids,
    BankMessageStatus status,
  ) async {
    // Optimistic: the row moves tabs immediately, the store catches up.
    final previous = state.messages;
    emit(state.copyWith(
      action: BankSyncAction.working,
      messages: [
        for (final m in previous)
          if (ids.contains(m.id)) m.copyWith(status: status) else m,
      ],
    ));

    final result = await _setStatus(ids, status);

    result.fold(
      (failure) => emit(state.copyWith(
        action: BankSyncAction.failure,
        messages: previous,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(action: BankSyncAction.statusChanged)),
    );
  }

  Future<void> _saveLink(BankLink link) async {
    final previous = state.link;
    emit(state.copyWith(action: BankSyncAction.working, link: link));

    final result = await _updateLink(link);

    result.fold(
      (failure) => emit(state.copyWith(
        action: BankSyncAction.failure,
        link: previous,
        errorMessage: failure.message,
      )),
      (stored) => emit(state.copyWith(
        action: BankSyncAction.linkUpdated,
        link: stored,
      )),
    );
  }

  void _emitFailure(Failure failure) => emit(state.copyWith(
        action: BankSyncAction.failure,
        errorMessage: failure.message,
      ));

  static List<BankMessage> _sorted(List<BankMessage> list) =>
      List.of(list)..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
}

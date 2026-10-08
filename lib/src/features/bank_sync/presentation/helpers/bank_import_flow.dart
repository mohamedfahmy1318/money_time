import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_sync_results.dart';
import 'package:mony_time/src/features/bank_sync/presentation/cubits/bank_sync_cubit.dart';
import 'package:mony_time/src/features/bank_sync/presentation/helpers/bank_display.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/paste_message_sheet.dart';
import 'package:mony_time/src/features/transactions/presentation/cubits/transactions_cubit.dart';

/// The inbox actions shared by the link hub, the inbox and the review screen.
///
/// * [importClear] / [importOne] add messages through the server's import
///   endpoints (never `PATCH status=imported`), then mirror the transactions
///   the server created into the local ledger ([TransactionsCubit]).
/// * [addPastedMessage] stores a pasted SMS; in automatic mode a confident
///   one comes back already imported.
/// * [ignoreMessage] / [restoreMessage] move a message between tabs; the
///   cubit applies it optimistically and this reports the server's answer.
/// * [refreshInbox] is the pull-to-refresh, with a toast when it fails.
///
/// Wrap the screen in [importListener]; the guards keep it from reacting to
/// actions fired by other screens on the shared cubit.
mixin BankImportFlow<T extends StatefulWidget> on State<T> {
  bool _importing = false;
  bool _submitting = false;
  bool _changingStatus = false;
  bool _refreshing = false;

  bool get isImporting => _importing;
  bool get isChangingStatus => _changingStatus;

  /// Runs after a user-initiated import succeeds — toast / navigate here.
  void onImported(int count, int skipped);

  /// Runs after a user-initiated ignore / restore is confirmed. [moved] is
  /// empty when the message had already changed elsewhere (the cubit
  /// reloads in that case).
  void onStatusChanged(List<BankMessage> moved) {
    if (moved.isEmpty) {
      showToast(
        context,
        message: 'bank_sync.changed_elsewhere'.tr(),
        status: 'info',
      );
      return;
    }
    showToast(
      context,
      message: moved.first.status == BankMessageStatus.ignored
          ? 'bank_sync.ignored_toast'.tr()
          : 'bank_sync.restored_toast'.tr(),
      status: 'info',
    );
  }

  void importClear(List<BankMessage> messages) => _startImport(() => context
      .read<BankSyncCubit>()
      .importMany([for (final m in messages) m.id]));

  void importOne(
    BankMessage message, {
    ImportOverrides overrides = ImportOverrides.none,
  }) =>
      _startImport(() => context
          .read<BankSyncCubit>()
          .importOne(message.id, overrides: overrides));

  void _startImport(Future<void> Function() run) {
    if (_importing) return;
    setState(() => _importing = true);
    run();
  }

  void ignoreMessage(BankMessage message) =>
      _startStatusChange(() => context.read<BankSyncCubit>().ignore(message.id));

  void restoreMessage(BankMessage message) => _startStatusChange(
      () => context.read<BankSyncCubit>().restore(message.id));

  void _startStatusChange(Future<void> Function() run) {
    if (_changingStatus) return;
    _changingStatus = true;
    run();
  }

  Future<void> refreshInbox() async {
    _refreshing = true;
    try {
      await context.read<BankSyncCubit>().refresh();
    } finally {
      _refreshing = false;
    }
  }

  Future<void> addPastedMessage() async {
    final cubit = context.read<BankSyncCubit>();
    final pasted = await showPasteMessageSheet(
      context,
      banks: cubit.state.linkedBanks,
    );
    if (pasted == null || !mounted) return;
    _submitting = true;
    await cubit.submit(sender: pasted.sender, body: pasted.body);
  }

  Widget importListener({required Widget child}) {
    return BlocListener<BankSyncCubit, BankSyncState>(
      listenWhen: (previous, current) => previous.action != current.action,
      listener: _onBankSyncChanged,
      child: child,
    );
  }

  void _onBankSyncChanged(BuildContext context, BankSyncState state) {
    switch (state.action) {
      case BankSyncAction.imported when _importing:
        setState(() => _importing = false);
        final result = state.lastImport!;
        _mirror([for (final r in result.imported) r.transaction]);
        onImported(result.imported.length, result.skipped.length);
      case BankSyncAction.submitted when _submitting:
        _submitting = false;
        _onSubmitted(state.lastSubmitted!);
      case BankSyncAction.statusChanged when _changingStatus:
        _changingStatus = false;
        onStatusChanged(state.lastMoved);
      case BankSyncAction.refreshFailed when _refreshing:
        showToast(
          context,
          message: state.errorMessage ?? 'shared.something_wrong'.tr(),
          status: 'error',
        );
      case BankSyncAction.failure
          when _importing || _submitting || _changingStatus:
        if (_importing) setState(() => _importing = false);
        _submitting = false;
        _changingStatus = false;
        showToast(
          context,
          message: state.errorMessage ?? 'shared.something_wrong'.tr(),
          status: 'error',
        );
      default:
        break;
    }
  }

  void _onSubmitted(SubmittedBankMessage submitted) {
    final message = submitted.message;
    if (submitted.duplicate) {
      showToast(
        context,
        message: 'bank_sync.already_have'.tr(),
        status: 'info',
      );
    } else if (submitted.transaction != null) {
      _mirror([submitted.transaction!]);
      showToast(context, message: 'bank_sync.added_automatically'.tr());
    } else if (!message.isTransaction) {
      showToast(
        context,
        message: 'bank_sync.filed_not_transaction'.tr(),
        status: 'info',
      );
    } else {
      showToast(context, message: 'bank_sync.added_to_inbox'.tr());
    }
  }

  void _mirror(List<ImportedTransaction> transactions) {
    if (transactions.isEmpty) return;
    context.read<TransactionsCubit>().addTransactions(
      [for (final t in transactions) t.toLedgerEntry()],
    );
  }
}

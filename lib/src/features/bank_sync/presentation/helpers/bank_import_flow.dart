import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/bank_sync/presentation/cubits/bank_sync_cubit.dart';
import 'package:mony_time/src/features/bank_sync/presentation/helpers/bank_display.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/paste_message_sheet.dart';
import 'package:mony_time/src/features/transactions/domain/entities/transaction.dart';
import 'package:mony_time/src/features/transactions/presentation/cubits/transactions_cubit.dart';

/// The import steps shared by the link hub, the inbox and the message review
/// screen:
///
/// * [importMessages] adds transactions through the app-wide
///   [TransactionsCubit] and, only once they are stored, marks their messages
///   imported in [BankSyncCubit];
/// * [addPastedMessage] ingests a pasted SMS and — in automatic mode, when it
///   reads cleanly — imports it straight away.
///
/// Wrap the screen in [importListener]; the guards keep it from reacting to
/// saves triggered by other screens on the shared cubits.
mixin BankImportFlow<T extends StatefulWidget> on State<T> {
  /// Message ids of the import in flight.
  List<String>? _importing;
  bool _automatic = false;
  bool _ingesting = false;

  bool get isImporting => _importing != null;

  /// Runs after a user-initiated import succeeds — toast / navigate here.
  void onImported(int count);

  /// [transactions] maps message id → the transaction it becomes.
  void importMessages(
    Map<String, Transaction> transactions, {
    bool automatic = false,
  }) {
    if (_importing != null || transactions.isEmpty) return;
    setState(() {
      _importing = transactions.keys.toList();
      _automatic = automatic;
    });
    context
        .read<TransactionsCubit>()
        .addTransactions(transactions.values.toList());
  }

  Future<void> addPastedMessage() async {
    final cubit = context.read<BankSyncCubit>();
    final banks = cubit.state.linkedBanks.isEmpty
        ? cubit.state.banks
        : cubit.state.linkedBanks;
    final pasted = await showPasteMessageSheet(context, banks: banks);
    if (pasted == null || !mounted) return;
    _ingesting = true;
    await cubit.ingest(sender: pasted.sender, body: pasted.body);
  }

  Widget importListener({required Widget child}) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TransactionsCubit, TransactionsState>(
          listenWhen: (previous, current) => previous.action != current.action,
          listener: _onTransactionsChanged,
        ),
        BlocListener<BankSyncCubit, BankSyncState>(
          listenWhen: (previous, current) => previous.action != current.action,
          listener: _onBankSyncChanged,
        ),
      ],
      child: child,
    );
  }

  void _onTransactionsChanged(BuildContext context, TransactionsState state) {
    final ids = _importing;
    if (ids == null) return;
    switch (state.action) {
      case TransactionsAction.saveSuccess:
        final automatic = _automatic;
        setState(() => _importing = null);
        context.read<BankSyncCubit>().markImported(ids);
        if (automatic) {
          showToast(context, message: 'bank_sync.added_automatically'.tr());
        } else {
          onImported(ids.length);
        }
      case TransactionsAction.failure:
        setState(() => _importing = null);
        showToast(
          context,
          message: state.errorMessage ?? 'shared.something_wrong'.tr(),
          status: 'error',
        );
      case TransactionsAction.idle:
      case TransactionsAction.saving:
      case TransactionsAction.deleteSuccess:
        break;
    }
  }

  void _onBankSyncChanged(BuildContext context, BankSyncState state) {
    if (!_ingesting) return;
    switch (state.action) {
      case BankSyncAction.ingested:
        _ingesting = false;
        final message = state.lastIngested!;
        if (!message.isTransaction) {
          showToast(
            context,
            message: 'bank_sync.filed_not_transaction'.tr(),
            status: 'info',
          );
        } else if (state.link.isAutomatic && !message.needsAttention) {
          importMessages(
            {message.id: message.toTransaction(state.bankById(message.bankId))},
            automatic: true,
          );
        } else {
          showToast(context, message: 'bank_sync.added_to_inbox'.tr());
        }
      case BankSyncAction.failure:
        _ingesting = false;
        showToast(
          context,
          message: state.errorMessage ?? 'shared.something_wrong'.tr(),
          status: 'error',
        );
      default:
        break;
    }
  }
}

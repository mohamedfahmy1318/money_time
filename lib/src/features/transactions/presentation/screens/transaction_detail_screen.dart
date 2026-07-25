import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/transactions/domain/entities/transaction.dart';
import 'package:mony_time/src/features/transactions/presentation/cubits/transactions_cubit.dart';
import 'package:mony_time/src/features/transactions/presentation/widgets/detail_row.dart';

/// Read-only view of one transaction with Edit and Delete actions.
///
/// Watches the app-wide [TransactionsCubit] by id so returning from the edit
/// flow shows the fresh values.
class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({super.key, required this.transaction});

  final Transaction transaction;

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  /// True after this screen fired the delete — guards the shared cubit's
  /// action stream against events triggered elsewhere.
  bool _deleting = false;

  Future<void> _confirmDelete(Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('transactions.delete_title'.tr()),
        content: Text('transactions.delete_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('shared.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'transactions.delete'.tr(),
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    _deleting = true;
    await context.read<TransactionsCubit>().deleteTransaction(transaction.id);
  }

  void _onStateChanged(BuildContext context, TransactionsState state) {
    if (!_deleting) return;
    switch (state.action) {
      case TransactionsAction.deleteSuccess:
        _deleting = false;
        showToast(context, message: 'transactions.deleted'.tr());
        context.popOrGo(AppRoutes.home);
      case TransactionsAction.failure:
        _deleting = false;
        showToast(
          context,
          message: state.errorMessage ?? 'shared.something_wrong'.tr(),
          status: 'error',
        );
      case TransactionsAction.idle:
      case TransactionsAction.saving:
      case TransactionsAction.saveSuccess:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransactionsCubit, TransactionsState>(
      listenWhen: (previous, current) => previous.action != current.action,
      listener: _onStateChanged,
      builder: (context, state) {
        // Live version — falls back to the pushed value mid-delete.
        final transaction =
            state.byId(widget.transaction.id) ?? widget.transaction;
        final locale = context.locale.toString();

        return Scaffold(
          appBar: AppTopBar(
            title: 'transactions.detail_title'.tr(),
            actions: [
              IconButton(
                onPressed: () => _edit(transaction),
                icon: Icon(
                  Icons.edit_outlined,
                  size: 20.sp,
                  color: context.colors.onSurface,
                ),
              ),
              SizedBox(width: 8.w),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 12.h),
              child: Column(
                children: [
                  Container(
                    width: 64.r,
                    height: 64.r,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.colors.primaryContainer,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      transaction.categoryEmoji,
                      style: TextStyle(fontSize: 23.sp),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    '${transaction.isIncome ? '+' : '−'}'
                    '${moneyWithSymbol(transaction.amount)}',
                    style: context.textTheme.headlineMedium?.copyWith(
                      color: transaction.isIncome
                          ? context.colors.tertiary
                          : context.colors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 31.sp,
                      letterSpacing: -0.32,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    '${transaction.categoryLabel} · ${transaction.type.label}',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 22.h),
                  AppSoftCard(
                    padding: EdgeInsets.symmetric(horizontal: 15.w),
                    child: Column(
                      children: [
                        SizedBox(height: 2.h),
                        DetailRow(
                          label: 'transactions.date'.tr(),
                          value: AppDate.fullDate(transaction.date, locale),
                        ),
                        DetailRow(
                          label: 'transactions.category'.tr(),
                          value:
                              '${transaction.categoryEmoji} ${transaction.categoryLabel}',
                        ),
                        DetailRow(
                          label: 'transactions.source'.tr(),
                          value: transaction.isAuto
                              ? '⚡ ${'transactions.auto_source'.tr()}'
                              : transaction.source,
                          valueColor: transaction.isAuto
                              ? context.colors.primary
                              : null,
                        ),
                        DetailRow(
                          label: 'transactions.note'.tr(),
                          value: transaction.note.isEmpty
                              ? '—'
                              : transaction.note,
                          valueColor: context.colors.onSurfaceVariant,
                          showDivider: false,
                        ),
                        SizedBox(height: 2.h),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: AppGradientButton(
                          label: 'transactions.edit'.tr(),
                          onPressed: () => _edit(transaction),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _DeleteButton(
                          isLoading: state.isSaving && _deleting,
                          onTap: () => _confirmDelete(transaction),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _edit(Transaction transaction) =>
      context.push(AppRoutes.addTransaction, extra: transaction);
}

/// Soft-danger action: tinted red fill, red bold label.
class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onTap, this.isLoading = false});

  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 49.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.errorContainer,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: isLoading
            ? SizedBox(
                width: 18.r,
                height: 18.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.colors.error,
                ),
              )
            : Text(
                'transactions.delete'.tr(),
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.colors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 15.sp,
                ),
              ),
      ),
    );
  }
}

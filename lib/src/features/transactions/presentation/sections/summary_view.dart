import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/transactions/domain/entities/transaction.dart';
import 'package:mony_time/src/features/transactions/presentation/cubits/transactions_cubit.dart';
import 'package:mony_time/src/features/transactions/presentation/sections/month_summary_strip.dart';

/// Placeholder monthly budget until budgets become real data.
const double _kMonthlyBudget = 5000;

/// Summary ledger view: month totals, the accounts aggregate, budget
/// consumption and the export action.
class SummaryView extends StatelessWidget {
  const SummaryView({super.key, required this.transactions});

  /// The month's transactions (already filtered by the hub).
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final expense = TransactionsState.sumExpense(transactions);
    final budgetFraction = expense / _kMonthlyBudget;
    final budgetPercent = (budgetFraction * 100).round();

    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 100.h),
      children: [
        MonthSummaryStrip(transactions: transactions),
        SizedBox(height: 24.h),
        _sectionLabel(context, 'transactions.accounts'.tr()),
        SizedBox(height: 10.h),
        AppSoftCard(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
          child: Row(
            children: [
              Container(
                width: 36.w,
                height: 34.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Text('🏦', style: TextStyle(fontSize: 12.sp)),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'transactions.accounts_expense'.tr(),
                  style: context.textTheme.titleSmall?.copyWith(
                    color: context.colors.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                formatMoney(expense),
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.8.sp,
                  letterSpacing: -0.13,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        _sectionLabel(context, 'transactions.budget'.tr()),
        SizedBox(height: 10.h),
        AppSoftCard(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'transactions.total_budget'.tr(),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurface,
                        fontSize: 11.8.sp,
                      ),
                    ),
                  ),
                  Text(
                    '$budgetPercent%',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurface,
                      fontSize: 12.sp,
                      letterSpacing: -0.12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              GradientProgressBar(fraction: budgetFraction, height: 8.h),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        _ExportButton(
          onTap: () => showToast(
            context,
            message: 'transactions.export_soon'.tr(),
            status: 'info',
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Text(
        text.toUpperCase(),
        style: context.textTheme.labelSmall?.copyWith(
          color: context.colors.onSurfaceVariant,
          fontWeight: FontWeight.bold,
          fontSize: 11.5.sp,
          letterSpacing: 0.58,
        ),
      );
}

/// Flat tinted tertiary action — visually quieter than the gradient CTA.
class _ExportButton extends StatelessWidget {
  const _ExportButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 49.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.grid_on_rounded,
              size: 16.sp,
              color: AppColors.primaryDark,
            ),
            SizedBox(width: 8.w),
            Text(
              'transactions.export_excel'.tr(),
              style: context.textTheme.titleSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: 15.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

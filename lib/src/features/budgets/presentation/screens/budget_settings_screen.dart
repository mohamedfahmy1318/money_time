import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/auth/presentation/helpers/auth_actions.dart';
import 'package:mony_time/src/features/budgets/domain/entities/budget.dart';
import 'package:mony_time/src/features/budgets/presentation/cubits/budgets_cubit.dart';
import 'package:mony_time/src/features/transactions/presentation/widgets/month_stepper.dart';

/// Budget Setting: month stepper, Income / Expense scope tabs and the list of
/// per-category limits. Tapping a row opens the keypad editor.
class BudgetSettingsScreen extends StatefulWidget {
  const BudgetSettingsScreen({super.key});

  @override
  State<BudgetSettingsScreen> createState() => _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends State<BudgetSettingsScreen> {
  /// 0 income · 1 expense — Expense first since caps are the common case.
  int _tab = 1;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BudgetsCubit>().state;
    final budgets = state
        .ofType(_tab == 0 ? TransactionType.income : TransactionType.expense);
    final locale = context.locale.toString();

    return Scaffold(
      appBar: AppTopBar(title: 'budgets.setting'.tr()),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(height: 2.h),
            MonthStepper(
              label: AppDate.monthYear(_month, locale),
              onPrev: () => setState(() =>
                  _month = DateTime(_month.year, _month.month - 1)),
              onNext: () => setState(() =>
                  _month = DateTime(_month.year, _month.month + 1)),
            ),
            SizedBox(height: 2.h),
            UnderlineTabs(
              labels: [
                'transactions.income'.tr(),
                'transactions.expense'.tr(),
              ],
              selectedIndex: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            SizedBox(height: 8.h),
            Expanded(
              child: state.isLoading
                  ? const AppLoading()
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
                      itemCount: budgets.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 1,
                        color: context.colors.outlineVariant,
                      ),
                      itemBuilder: (context, index) =>
                          _BudgetRow(budget: budgets[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.budget});

  final Budget budget;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.guardedPush(AppRoutes.budgetEdit, extra: budget),
      child: SizedBox(
        height: 47.h,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${budget.categoryEmoji}  ${budget.categoryLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: context.colors.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5.sp,
                  ),
                ),
              ),
              Text(
                moneyWithSymbol(budget.limit),
                style: context.textTheme.labelMedium?.copyWith(
                  color: budget.isSet
                      ? context.colors.onSurface
                      : context.colors.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                  letterSpacing: -0.13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

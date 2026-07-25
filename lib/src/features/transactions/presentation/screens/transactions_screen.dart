import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/transactions/domain/entities/transaction.dart';
import 'package:mony_time/src/features/transactions/presentation/cubits/transactions_cubit.dart';
import 'package:mony_time/src/features/transactions/presentation/models/transaction_filter.dart';
import 'package:mony_time/src/features/transactions/presentation/sections/calendar_view.dart';
import 'package:mony_time/src/features/transactions/presentation/sections/daily_view.dart';
import 'package:mony_time/src/features/transactions/presentation/sections/monthly_view.dart';
import 'package:mony_time/src/features/transactions/presentation/sections/summary_view.dart';
import 'package:mony_time/src/features/transactions/presentation/widgets/month_stepper.dart';

/// The ledger hub tab: Daily / Calendar / Monthly / Summary views of the
/// shared transaction list, with a month (or year) stepper, search and
/// filtering. Data comes from the app-wide [TransactionsCubit]; this screen
/// only owns view-local UI state.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  /// View indices: 0 Daily · 1 Calendar · 2 Monthly · 3 Summary.
  static const _daily = 0, _monthly = 2;

  int _view = _daily;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDay;
  TransactionFilter _filter = const TransactionFilter();

  void _step(int direction) {
    setState(() {
      _month = _view == _monthly
          ? DateTime(_month.year + direction, _month.month)
          : DateTime(_month.year, _month.month + direction);
      _selectedDay = null;
    });
  }

  Future<void> _openFilter() async {
    final result = await context.push<TransactionFilter>(
      AppRoutes.transactionsFilter,
      extra: FilterScreenArgs(month: _month, current: _filter),
    );
    if (result != null) setState(() => _filter = result);
  }

  void _openDetail(Transaction transaction) =>
      context.push(AppRoutes.transactionDetail, extra: transaction);

  void _pickMonth(DateTime month) => setState(() {
        _month = month;
        _selectedDay = null;
        _view = _daily;
      });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionsCubit>().state;
    final monthTransactions = _filter.apply(state.monthOf(_month));
    final locale = context.locale.toString();

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(22.w, 8.h, 22.w, 0),
            child: Row(
              children: [
                _HeaderIcon(
                  icon: Icons.search_rounded,
                  onTap: () => context.push(AppRoutes.transactionsSearch),
                ),
                Expanded(
                  child: Text(
                    'transactions.ledger_title'.tr(),
                    textAlign: TextAlign.center,
                    style: context.textTheme.titleLarge?.copyWith(
                      color: context.colors.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                    ),
                  ),
                ),
                _HeaderIcon(
                  icon: Icons.tune_rounded,
                  // Tinted while a filter is active so it's discoverable.
                  color: _filter.isActive ? context.colors.primary : null,
                  onTap: _openFilter,
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          MonthStepper(
            label: _view == _monthly
                ? '${_month.year}'
                : AppDate.monthYear(_month, locale),
            onPrev: () => _step(-1),
            onNext: () => _step(1),
          ),
          SizedBox(height: 2.h),
          UnderlineTabs(
            labels: [
              'transactions.tab_daily'.tr(),
              'transactions.tab_calendar'.tr(),
              'transactions.tab_monthly'.tr(),
              'transactions.tab_summary'.tr(),
            ],
            selectedIndex: _view,
            onChanged: (i) => setState(() => _view = i),
          ),
          SizedBox(height: 14.h),
          Expanded(child: _body(state, monthTransactions)),
        ],
      ),
    );
  }

  Widget _body(TransactionsState state, List<Transaction> monthTransactions) {
    if (state.isLoading || state.status == TransactionsStatus.initial) {
      return const AppLoading();
    }
    if (state.status == TransactionsStatus.failure) {
      return AppErrorWidget(
        message: state.errorMessage,
        onRetry: () => context.read<TransactionsCubit>().loadTransactions(),
      );
    }

    return IndexedStack(
      index: _view,
      children: [
        DailyView(
          transactions: monthTransactions,
          onTapTransaction: _openDetail,
        ),
        CalendarView(
          month: _month,
          transactions: monthTransactions,
          selectedDay: _selectedDay,
          onSelectDay: (day) => setState(() => _selectedDay = day),
          onTapTransaction: _openDetail,
        ),
        MonthlyView(
          year: _month.year,
          state: state,
          onPickMonth: _pickMonth,
        ),
        SummaryView(transactions: monthTransactions),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.onTap, this.color});

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.all(4.r),
        child: Icon(
          icon,
          size: 20.sp,
          color: color ?? context.colors.onSurface,
        ),
      ),
    );
  }
}

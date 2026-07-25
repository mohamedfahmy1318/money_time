import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/transactions/domain/entities/transaction.dart';
import 'package:mony_time/src/features/transactions/presentation/widgets/transaction_card.dart';
import 'package:mony_time/src/features/transactions/presentation/widgets/transaction_row.dart';

/// Calendar ledger view: a Sunday-first month grid where days with activity
/// wear a mint pill, plus a card listing the selected day's transactions.
class CalendarView extends StatelessWidget {
  const CalendarView({
    super.key,
    required this.month,
    required this.transactions,
    required this.selectedDay,
    required this.onSelectDay,
    required this.onTapTransaction,
  });

  final DateTime month;

  /// The month's transactions (already filtered by the hub).
  final List<Transaction> transactions;

  /// Hub-owned selection; when null the view falls back to today (current
  /// month) or the latest active day.
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onSelectDay;
  final ValueChanged<Transaction> onTapTransaction;

  DateTime? get _effectiveSelectedDay {
    if (selectedDay != null) return selectedDay;
    final now = DateTime.now();
    if (month.year == now.year && month.month == now.month) {
      return DateTime(now.year, now.month, now.day);
    }
    if (transactions.isNotEmpty) return transactions.first.day;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();
    final selected = _effectiveSelectedDay;
    final activeDays = {for (final t in transactions) t.day};
    final dayTransactions = selected == null
        ? const <Transaction>[]
        : transactions.where((t) => t.day == selected).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 100.h),
      children: [
        _WeekdayHeader(locale: locale),
        SizedBox(height: 6.h),
        _MonthGrid(
          month: month,
          activeDays: activeDays,
          selected: selected,
          onSelectDay: onSelectDay,
        ),
        SizedBox(height: 22.h),
        if (dayTransactions.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 24.h),
            child: Text(
              'transactions.empty_day'.tr(),
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          )
        else
          TransactionCard(
            rows: [
              for (final t in dayTransactions)
                TransactionRow(
                  transaction: t,
                  title:
                      '${AppDate.shortDate(t.date, locale)} · ${t.categoryLabel}',
                  subtitle: '',
                  onTap: () => onTapTransaction(t),
                ),
            ],
          ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.locale});

  final String locale;

  @override
  Widget build(BuildContext context) {
    // 1 Jan 2023 was a Sunday — narrow weekday letters, Sunday first.
    final letters = [
      for (var i = 0; i < 7; i++)
        DateFormat('EEEEE', locale).format(DateTime(2023, 1, 1 + i)),
    ];

    return Row(
      children: [
        for (final letter in letters)
          Expanded(
            child: Text(
              letter,
              textAlign: TextAlign.center,
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: 11.sp,
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.activeDays,
    required this.selected,
    required this.onSelectDay,
  });

  final DateTime month;
  final Set<DateTime> activeDays;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday % 7; // Sunday-first offset
    final prevMonthLast = DateTime(month.year, month.month, 0).day;
    final rowCount = ((leading + daysInMonth) / 7).ceil();

    return Column(
      children: [
        for (var row = 0; row < rowCount; row++)
          SizedBox(
            height: 31.h,
            child: Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: _cell(context, row * 7 + col - leading + 1,
                        daysInMonth, prevMonthLast, col),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(BuildContext context, int dayNumber, int daysInMonth,
      int prevMonthLast, int column) {
    // Adjacent-month days: faded, not selectable.
    if (dayNumber < 1 || dayNumber > daysInMonth) {
      final label = dayNumber < 1
          ? '${prevMonthLast + dayNumber}'
          : '${dayNumber - daysInMonth}';
      return Center(
        child: Text(
          label,
          style: _dayStyle(
            context,
            context.colors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    final day = DateTime(month.year, month.month, dayNumber);
    final isActive = activeDays.contains(day);
    final isSelected = day == selected;
    final isSaturday = column == 6;

    final textColor = isActive
        ? context.colors.onPrimaryContainer
        : isSaturday
            ? AppColors.softRed
            : context.colors.onSurface;

    return GestureDetector(
      onTap: () => onSelectDay(day),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Container(
          width: 34.w,
          height: 28.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? context.colors.primaryContainer : null,
            border: isSelected
                ? Border.all(color: context.colors.primary, width: 1.5)
                : null,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text('$dayNumber', style: _dayStyle(context, textColor)),
        ),
      ),
    );
  }

  TextStyle? _dayStyle(BuildContext context, Color color) =>
      context.textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: 10.8.sp,
      );
}

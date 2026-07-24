import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/home/presentation/models/home_data.dart';

/// One row in the "Recent" transactions card: emoji tile, title + date, and a
/// signed amount coloured by direction (income = accent blue, expense = red).
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final HomeTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final amountColor =
        transaction.isIncome ? context.colors.tertiary : context.colors.error;
    final sign = transaction.isIncome ? '+' : '−';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(13.r),
            ),
            alignment: Alignment.center,
            child: Text(transaction.emoji, style: TextStyle(fontSize: 14.sp)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: context.colors.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                Text(
                  transaction.date,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$sign${transaction.amount}',
            style: context.textTheme.titleSmall?.copyWith(
              color: amountColor,
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
              letterSpacing: -0.14,
            ),
          ),
        ],
      ),
    );
  }
}

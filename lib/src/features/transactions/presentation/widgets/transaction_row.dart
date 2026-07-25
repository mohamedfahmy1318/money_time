import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/transactions/domain/entities/transaction.dart';

/// One transaction in a list card: emoji tile, title over an optional muted
/// subtitle, and the signed coloured amount. Defaults show the category as
/// title and the source as subtitle; callers override for other contexts
/// (search shows `date · source`, the calendar card shows `date · category`).
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.transaction,
    this.title,
    this.subtitle,
    this.onTap,
  });

  final Transaction transaction;
  final String? title;

  /// Pass `''` to hide the subtitle line entirely.
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final resolvedTitle = title ?? transaction.categoryLabel;
    final resolvedSubtitle = subtitle ?? transaction.source;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 38.r,
              height: 38.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(13.r),
              ),
              child: Text(
                transaction.categoryEmoji,
                style: TextStyle(fontSize: 15.sp),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resolvedTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: context.colors.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                  if (resolvedSubtitle.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      resolvedSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              signedMoney(transaction.amount, isIncome: transaction.isIncome),
              style: context.textTheme.titleSmall?.copyWith(
                color: transaction.isIncome
                    ? context.colors.tertiary
                    : context.colors.error,
                fontWeight: FontWeight.bold,
                fontSize: 13.7.sp,
                letterSpacing: -0.14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

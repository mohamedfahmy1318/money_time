import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/reports/presentation/models/report_data.dart';

/// A transaction-style row: emoji tile, title over a muted subtitle, and a
/// coloured amount. Reused by the Note list (expense red) and the assets row
/// (income blue) via [amountColor].
class ReportListRow extends StatelessWidget {
  const ReportListRow({
    super.key,
    required this.entry,
    required this.amountColor,
  });

  final ReportEntry entry;
  final Color amountColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38.r,
          height: 38.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(13.r),
          ),
          child: Text(entry.emoji, style: TextStyle(fontSize: 15.sp)),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                entry.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          entry.amount,
          style: context.textTheme.titleSmall?.copyWith(
            color: amountColor,
            fontWeight: FontWeight.bold,
            fontSize: 13.7.sp,
            letterSpacing: -0.14,
          ),
        ),
      ],
    );
  }
}

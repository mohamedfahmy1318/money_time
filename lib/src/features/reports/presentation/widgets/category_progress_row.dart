import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/reports/presentation/models/report_data.dart';

/// A category breakdown row: emoji tile, name over an emerald progress bar, and
/// the amount on the trailing edge.
class CategoryProgressRow extends StatelessWidget {
  const CategoryProgressRow({super.key, required this.data});

  final CategorySpend data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34.r,
          height: 34.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(11.r),
          ),
          child: Text(data.emoji, style: TextStyle(fontSize: 15.sp)),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.label,
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 7.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: Stack(
                  children: [
                    Container(height: 6.h, color: context.colors.surface),
                    FractionallySizedBox(
                      widthFactor: data.fraction.clamp(0.0, 1.0),
                      child: Container(
                        height: 6.h,
                        decoration: const BoxDecoration(gradient: AppGradients.primaryButton),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          data.amount,
          style: context.textTheme.titleSmall?.copyWith(
            color: context.colors.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 13.sp,
          ),
        ),
      ],
    );
  }
}

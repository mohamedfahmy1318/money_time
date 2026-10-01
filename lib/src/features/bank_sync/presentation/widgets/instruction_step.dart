import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// One numbered step in a vertical guide: a tinted number badge joined to the
/// next step by a hairline, a title, optional copy and an optional [child]
/// (chips, a button …) beneath.
class InstructionStep extends StatelessWidget {
  const InstructionStep({
    super.key,
    required this.number,
    required this.title,
    this.description,
    this.child,
    this.isLast = false,
  });

  final int number;
  final String title;
  final String? description;
  final Widget? child;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 26.r,
                height: 26.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: context.textTheme.labelMedium?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: EdgeInsets.symmetric(vertical: 4.h),
                    color: context.colors.outlineVariant,
                  ),
                ),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 3.h, bottom: isLast ? 0 : 18.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: context.colors.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5.sp,
                    ),
                  ),
                  if (description != null) ...[
                    SizedBox(height: 3.h),
                    Text(
                      description!,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                        fontSize: 11.5.sp,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (child != null) ...[
                    SizedBox(height: 8.h),
                    child!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

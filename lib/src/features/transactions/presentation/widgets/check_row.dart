import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// A row of the filter checklist: custom rounded checkbox, a bold label
/// (usually emoji-prefixed) and an optional trailing red amount.
class CheckRow extends StatelessWidget {
  const CheckRow({
    super.key,
    required this.label,
    required this.checked,
    required this.onTap,
    this.amount,
    this.amountColor,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;

  /// Pre-signed amount (`−980`); omitted on the "All" row.
  final String? amount;

  /// Amount colour; defaults to the expense red.
  final Color? amountColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 51.h,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AppDurations.fast,
                curve: AppCurves.standard,
                width: 20.r,
                height: 20.r,
                decoration: BoxDecoration(
                  color: checked ? context.colors.primary : null,
                  border: checked
                      ? null
                      : Border.all(
                          color: context.colors.outlineVariant, width: 2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: checked
                    ? Icon(Icons.check_rounded,
                        size: 14.sp, color: Colors.white)
                    : null,
              ),
              SizedBox(width: 13.w),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: context.colors.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5.sp,
                  ),
                ),
              ),
              if (amount != null)
                Text(
                  amount!,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: amountColor ?? context.colors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.8.sp,
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

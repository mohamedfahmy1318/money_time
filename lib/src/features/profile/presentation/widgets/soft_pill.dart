import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// A small mint status pill (Premium Member, Connected …): the tonal
/// `primaryContainer` fill with `onPrimaryContainer` text, plus an optional
/// leading or trailing glyph.
class SoftPill extends StatelessWidget {
  const SoftPill({
    super.key,
    required this.label,
    this.leadingIcon,
    this.trailingIcon,
  });

  final String label;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final fg = context.colors.onPrimaryContainer;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: AppBorders.full,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 12.sp, color: fg),
            SizedBox(width: 4.w),
          ],
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.bold,
              fontSize: 11.sp,
            ),
          ),
          if (trailingIcon != null) ...[
            SizedBox(width: 4.w),
            Icon(trailingIcon, size: 12.sp, color: fg),
          ],
        ],
      ),
    );
  }
}

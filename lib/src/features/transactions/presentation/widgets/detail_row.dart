import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// A labelled key-value row (add-transaction form, transaction detail card):
/// muted label on the leading edge, bold value on the trailing edge, and an
/// optional hairline beneath.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.showDivider = true,
    this.onTap,
  });

  final String label;
  final String value;

  /// Overrides the default ink value colour (e.g. emerald for the auto
  /// source, muted for the note).
  final Color? valueColor;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 47.h,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  bottom: BorderSide(color: context.colors.outlineVariant),
                )
              : null,
        ),
        child: Row(
          children: [
            Text(
              label,
              style: context.textTheme.titleSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: 14.5.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleSmall?.copyWith(
                  color: valueColor ?? context.colors.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

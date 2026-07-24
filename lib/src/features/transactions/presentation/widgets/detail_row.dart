import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// One labelled row in the add-transaction details list: a muted label on the
/// leading edge, a bold value on the trailing edge, and a hairline beneath.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
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
          border: Border(
            bottom: BorderSide(color: context.colors.outlineVariant),
          ),
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
                  color: context.colors.onSurface,
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

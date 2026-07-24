import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// A row in the profile menu: a tinted icon tile, a label, and a trailing
/// affordance (a chevron by default, or a custom [trailing] such as a pill).
class ProfileMenuRow extends StatelessWidget {
  const ProfileMenuRow({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
        child: Row(
          children: [
            Container(
              width: 30.r,
              height: 30.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(9.r),
              ),
              child: Icon(icon, size: 16.sp, color: context.colors.primary),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5.sp,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18.sp,
                  color: context.colors.onSurfaceVariant,
                ),
          ],
        ),
      ),
    );
  }
}

import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// A radio card for one import mode: icon tile, title (with an optional
/// [badge]), supporting copy and a radio mark. The selected card takes a
/// brand hairline and a faint brand wash.
class ImportModeOption extends StatelessWidget {
  const ImportModeOption({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.06)
              : context.colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: selected ? primary : context.colors.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13.r),
              ),
              child: Icon(icon, size: 19.sp, color: primary),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 4.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        title,
                        style: context.textTheme.titleSmall?.copyWith(
                          color: context.colors.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 7.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            borderRadius: AppBorders.full,
                          ),
                          child: Text(
                            badge!,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 9.5.sp,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                      fontSize: 11.5.sp,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            _RadioMark(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primary;

    return Container(
      width: 20.r,
      height: 20.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? primary : context.colors.outlineVariant,
          width: 1.5,
        ),
      ),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        width: selected ? 10.r : 0,
        height: selected ? 10.r : 0,
        decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
      ),
    );
  }
}

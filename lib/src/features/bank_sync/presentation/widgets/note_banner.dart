import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

enum NoteTone { neutral, warning }

/// An inline explanatory note — a privacy promise, or an amber heads-up when
/// something needs the user's eye.
class NoteBanner extends StatelessWidget {
  const NoteBanner({
    super.key,
    required this.icon,
    required this.text,
    this.title,
    this.tone = NoteTone.neutral,
  });

  final IconData icon;
  final String text;
  final String? title;
  final NoteTone tone;

  @override
  Widget build(BuildContext context) {
    final accent = tone == NoteTone.warning
        ? context.appColors.warning
        : context.colors.primary;

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17.sp, color: accent),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: context.textTheme.labelLarge?.copyWith(
                      color: context.colors.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                ],
                Text(
                  text,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    fontSize: 11.5.sp,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

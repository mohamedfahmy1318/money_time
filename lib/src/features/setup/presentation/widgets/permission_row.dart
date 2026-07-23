import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/setup/presentation/widgets/pill_toggle.dart';

/// One permission entry on the enable-features screen: a coloured icon tile,
/// a title with supporting copy, and a [PillToggle].
class PermissionRow extends StatelessWidget {
  const PermissionRow({
    super.key,
    required this.iconColor,
    required this.emoji,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final Color iconColor;
  final String emoji;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(14.r),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: TextStyle(fontSize: 18.sp)),
          ),
          SizedBox(width: 13.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: context.colors.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    fontSize: 11.5.sp,
                    height: 16.68 / 11.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: PillToggle(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

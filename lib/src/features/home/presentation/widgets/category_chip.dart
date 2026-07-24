import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// A category shortcut: a coloured tile (emoji) or the gradient "add" tile,
/// with a caption beneath it.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.emoji,
    required this.tint,
    this.onTap,
  })  : isAdd = false;

  const CategoryChip.add({
    super.key,
    required this.label,
    this.onTap,
  })  : emoji = null,
        tint = null,
        isAdd = true;

  final String label;
  final String? emoji;
  final Color? tint;
  final bool isAdd;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 44.h,
            decoration: BoxDecoration(
              color: isAdd ? null : tint,
              gradient: isAdd ? AppGradients.primaryButton : null,
              borderRadius: BorderRadius.circular(14.r),
            ),
            alignment: Alignment.center,
            child: isAdd
                ? Icon(Icons.add_rounded, color: Colors.white, size: 22.sp)
                : Text(emoji!, style: TextStyle(fontSize: 20.sp)),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(
              color: isAdd ? context.colors.primary : context.colors.onSurface,
              fontWeight: isAdd ? FontWeight.bold : FontWeight.w500,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// A row on the category-management list: a red delete button, the emoji + name,
/// and trailing edit and reorder affordances.
class CategoryManageRow extends StatelessWidget {
  const CategoryManageRow({
    super.key,
    required this.emoji,
    required this.label,
    required this.onDelete,
    required this.onEdit,
  });

  final String emoji;
  final String label;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 53.h,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Row(
          children: [
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 22.r,
                height: 22.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.error,
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Icon(Icons.remove_rounded, size: 15.sp, color: Colors.white),
              ),
            ),
            SizedBox(width: 13.w),
            Expanded(
              child: Text(
                '$emoji  $label',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5.sp,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            GestureDetector(
              onTap: onEdit,
              child: Icon(
                Icons.edit_outlined,
                size: 16.sp,
                color: context.colors.onSurfaceVariant,
              ),
            ),
            SizedBox(width: 14.w),
            Icon(
              Icons.drag_handle_rounded,
              size: 16.sp,
              color: context.colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

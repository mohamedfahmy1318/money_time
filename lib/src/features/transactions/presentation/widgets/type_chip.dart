import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// Small rounded filter pill (All / Income / Expense) on the search screen:
/// mint tonal when selected, white with a hairline border otherwise.
class TypeChip extends StatelessWidget {
  const TypeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 24.h,
        padding: EdgeInsets.symmetric(horizontal: 11.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? context.colors.primaryContainer
              : context.colors.surfaceContainerLowest,
          border: selected
              ? null
              : Border.all(color: context.colors.outlineVariant),
          borderRadius: AppBorders.full,
        ),
        child: Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: selected
                ? context.colors.onPrimaryContainer
                : context.colors.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 11.sp,
          ),
        ),
      ),
    );
  }
}

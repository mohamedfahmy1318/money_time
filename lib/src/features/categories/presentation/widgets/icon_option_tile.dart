import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// A single emoji option in the add-category icon picker. A white rounded tile
/// that gains an emerald ring/tint when it is the chosen icon.
class IconOptionTile extends StatelessWidget {
  const IconOptionTile({
    super.key,
    required this.emoji,
    required this.selected,
    this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44.r,
        height: 44.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? context.colors.primaryContainer
              : context.colors.surfaceContainerLowest,
          border: Border.all(
            color: selected ? context.colors.primary : context.colors.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Text(emoji, style: TextStyle(fontSize: 15.sp)),
      ),
    );
  }
}

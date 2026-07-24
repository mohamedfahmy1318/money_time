import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// A selectable colour dot on the add-category screen. When [selected] it wears
/// a white gap ring and a matching outer ring.
///
/// Named `ColorSwatchDot` (not `ColorSwatch`) to avoid clashing with Flutter's
/// painting `ColorSwatch` class.
class ColorSwatchDot extends StatelessWidget {
  const ColorSwatchDot({
    super.key,
    required this.color,
    required this.selected,
    this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 30.r,
        height: 30.r,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          // Painted back-to-front: outer colour ring, then a white gap ring,
          // then the fill sits on top — matching the Figma double ring.
          boxShadow: selected
              ? [
                  BoxShadow(color: color, spreadRadius: 5.r),
                  BoxShadow(
                    color: context.colors.surfaceContainerLowest,
                    spreadRadius: 3.r,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

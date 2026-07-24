import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// A category cell in the picker grid: a rounded emoji tile with a caption.
///
/// Three looks: a normal white tile, the emerald gradient tile for the current
/// selection, and a dashed "add" tile (via [CategoryPickTile.add]).
class CategoryPickTile extends StatelessWidget {
  const CategoryPickTile({
    super.key,
    required this.emoji,
    required this.label,
    required this.selected,
    this.onTap,
  })  : isAdd = false;

  const CategoryPickTile.add({
    super.key,
    required this.label,
    this.onTap,
  })  : emoji = null,
        selected = false,
        isAdd = true;

  final String? emoji;
  final String label;
  final bool selected;
  final bool isAdd;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 52.r,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _tile(context),
            SizedBox(height: 7.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: context.textTheme.labelSmall?.copyWith(
                  color: selected ? context.colors.onSurface : context.colors.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 10.5.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context) {
    final tile = Container(
      width: 52.r,
      height: 52.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? null : context.colors.surfaceContainerLowest,
        gradient: selected ? AppGradients.primaryButton : null,
        border: isAdd
            ? null
            : selected
                ? null
                : Border.all(color: context.colors.outlineVariant),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: isAdd
          ? Icon(Icons.add_rounded, size: 20.sp, color: context.colors.onSurfaceVariant)
          : Text(emoji!, style: TextStyle(fontSize: 17.sp)),
    );

    if (!isAdd) return tile;

    // Dashed outline for the add tile.
    return CustomPaint(
      painter: _DashedRRectPainter(
        color: context.colors.outlineVariant,
        radius: 16.r,
      ),
      child: tile,
    );
  }
}

/// Strokes a rounded rectangle with an even dash pattern.
class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    const dashWidth = 4.0;
    const dashGap = 3.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

import 'dart:math' as math;

import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// A small donut showing a percentage: a light track with a coloured arc
/// sweeping clockwise from 12 o'clock, the percentage centred inside.
class PercentRing extends StatelessWidget {
  const PercentRing({
    super.key,
    required this.fraction,
    required this.color,
    required this.caption,
  });

  /// 0..1 share drawn as the coloured arc.
  final double fraction;
  final Color color;

  /// Muted label under the ring (`Income` / `Expense`).
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 74.r,
          height: 74.r,
          child: CustomPaint(
            painter: _RingPainter(
              fraction: fraction.clamp(0.0, 1.0),
              color: color,
              track: context.colors.outlineVariant,
            ),
            child: Center(
              child: Text(
                '${(fraction.clamp(0.0, 1.0) * 100).round()}%',
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          caption,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
            fontWeight: FontWeight.w400,
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.color,
    required this.track,
  });

  final double fraction;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.082; // ≈6px on the 74px Figma ring
    final rect = Offset.zero & size;
    final inner = rect.deflate(stroke / 2 + size.width * 0.081);

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(inner, 0, math.pi * 2, false, trackPaint);

    if (fraction > 0) {
      final arcPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        inner,
        -math.pi / 2,
        math.pi * 2 * fraction,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.color != color ||
      oldDelegate.track != track;
}

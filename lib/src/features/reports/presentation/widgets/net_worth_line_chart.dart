import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// An emerald area/line sparkline of net-worth points with month labels and a
/// dot on the latest value.
class NetWorthLineChart extends StatelessWidget {
  const NetWorthLineChart({
    super.key,
    required this.points,
    required this.months,
  });

  final List<double> points;
  final List<String> months;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 120.h,
          width: double.infinity,
          child: CustomPaint(
            painter: _LinePainter(points: points, color: context.colors.primary),
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            for (final month in months)
              Expanded(
                child: Text(
                  month,
                  textAlign: TextAlign.center,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    fontSize: 9.5.sp,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.points, required this.color});

  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final minV = points.reduce((a, b) => a < b ? a : b);
    final maxV = points.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 1 ? 1 : maxV - minV;

    const topPad = 8.0;
    final usableH = size.height - topPad - 4;
    final dx = size.width / (points.length - 1);

    Offset at(int i) => Offset(
          dx * i,
          topPad + usableH - ((points[i] - minV) / range) * usableH,
        );

    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      line.lineTo(at(i).dx, at(i).dy);
    }

    // Gradient fill under the line.
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );

    // The line itself.
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dot on the latest point.
    final last = at(points.length - 1);
    canvas.drawCircle(last, 5, Paint()..color = Colors.white);
    canvas.drawCircle(last, 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}

import '../../imports/core_imports.dart';
import '../../imports/packages_imports.dart';

/// A slim rounded progress track filled left-to-right with the emerald brand
/// gradient — used by the reports category breakdown and the summary budget
/// card.
class GradientProgressBar extends StatelessWidget {
  const GradientProgressBar({
    super.key,
    required this.fraction,
    this.height,
  });

  /// Fill amount, 0..1.
  final double fraction;

  /// Track thickness; defaults to 6.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final barHeight = height ?? 6.h;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4.r),
      child: Stack(
        children: [
          Container(height: barHeight, color: context.colors.surface),
          FractionallySizedBox(
            widthFactor: fraction.clamp(0.0, 1.0),
            child: Container(
              height: barHeight,
              decoration:
                  const BoxDecoration(gradient: AppGradients.primaryButton),
            ),
          ),
        ],
      ),
    );
  }
}

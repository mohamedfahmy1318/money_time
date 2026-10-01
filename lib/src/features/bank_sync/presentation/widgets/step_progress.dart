import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// Segmented progress for a multi-step flow: [current] and every step before
/// it are filled.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.count, required this.current});

  final int count;

  /// Zero-based.
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) SizedBox(width: 6.w),
          Expanded(
            child: AnimatedContainer(
              duration: AppDurations.normal,
              curve: AppCurves.standard,
              height: 4.h,
              decoration: BoxDecoration(
                color: i <= current
                    ? context.colors.primary
                    : context.colors.outlineVariant,
                borderRadius: AppBorders.full,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

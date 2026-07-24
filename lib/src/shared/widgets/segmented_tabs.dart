import '../../imports/core_imports.dart';
import '../../imports/packages_imports.dart';

/// Visual style of the selected segment.
enum SegmentedToggleStyle {
  /// Emerald gradient pill with white text.
  gradient,

  /// White pill with a soft shadow and ink text.
  soft,
}

/// A pill segmented control on a page-coloured track: N labels, one selected.
/// The base for [TransactionTypeToggle] and the reports/period switchers.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.style = SegmentedToggleStyle.soft,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final SegmentedToggleStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38.h,
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: _Segment(
                label: labels[i],
                selected: i == selectedIndex,
                style: style,
                onTap: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.style,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final SegmentedToggleStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isGradient = style == SegmentedToggleStyle.gradient;

    final Color textColor;
    if (!selected) {
      textColor = context.colors.onSurfaceVariant;
    } else {
      textColor = isGradient ? Colors.white : context.colors.onSurface;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDurations.quick,
        curve: AppCurves.standard,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected && !isGradient
              ? context.colors.surfaceContainerLowest
              : null,
          gradient: selected && isGradient ? AppGradients.primaryButton : null,
          borderRadius: BorderRadius.circular(11.r),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.06),
                    offset: Offset(0, 4.h),
                    blurRadius: 7.r,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          maxLines: 1,
          style: context.textTheme.labelLarge?.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 12.5.sp,
          ),
        ),
      ),
    );
  }
}

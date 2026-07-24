import '../../imports/core_imports.dart';
import '../../imports/packages_imports.dart';

/// Visual style of the selected segment.
enum SegmentedToggleStyle {
  /// Emerald gradient pill with white text (add-transaction).
  gradient,

  /// White pill with a soft shadow and ink text (category screens).
  soft,
}

/// Segmented Income / Expense control on a page-coloured track. The selected
/// side is highlighted per [style]; the other is a muted label.
class TransactionTypeToggle extends StatelessWidget {
  const TransactionTypeToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.style = SegmentedToggleStyle.gradient,
    this.order = const [TransactionType.income, TransactionType.expense],
  });

  final TransactionType value;
  final ValueChanged<TransactionType> onChanged;
  final SegmentedToggleStyle style;

  /// Left-to-right ordering of the two segments (Figma flips it between
  /// screens).
  final List<TransactionType> order;

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
          for (final type in order)
            Expanded(
              child: _Segment(
                label: type.label,
                selected: type == value,
                style: style,
                onTap: () => onChanged(type),
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

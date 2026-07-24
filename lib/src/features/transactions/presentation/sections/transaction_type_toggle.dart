import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/transactions/presentation/models/transaction_type.dart';

/// Segmented Income / Expense control. The selected side is an emerald gradient
/// pill; the other is a muted label on the page background.
class TransactionTypeToggle extends StatelessWidget {
  const TransactionTypeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final TransactionType value;
  final ValueChanged<TransactionType> onChanged;

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
          for (final type in TransactionType.values)
            Expanded(
              child: _Segment(
                label: type.label,
                selected: type == value,
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
      child: AnimatedContainer(
        duration: AppDurations.quick,
        curve: AppCurves.standard,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.primaryButton : null,
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
            color: selected ? Colors.white : context.colors.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 12.5.sp,
          ),
        ),
      ),
    );
  }
}

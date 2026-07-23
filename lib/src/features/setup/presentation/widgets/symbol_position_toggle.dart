import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/setup/presentation/models/app_currency.dart';

/// Two-option segmented control choosing whether the currency symbol renders
/// in front of or behind the amount.
class SymbolPositionToggle extends StatelessWidget {
  const SymbolPositionToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final SymbolPosition value;
  final ValueChanged<SymbolPosition> onChanged;

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
          _segment(context, 'setup.symbol_front'.tr(), SymbolPosition.front),
          _segment(context, 'setup.symbol_back'.tr(), SymbolPosition.back),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, String label, SymbolPosition position) {
    final isSelected = value == position;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(position),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppCurves.standard,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? context.colors.surfaceContainerLowest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: context.colors.onSurface.withValues(alpha: 0.06),
                      offset: Offset(0, 4.h),
                      blurRadius: 7.r,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(
              color: isSelected
                  ? context.colors.onSurface
                  : context.colors.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              fontSize: 12.5.sp,
            ),
          ),
        ),
      ),
    );
  }
}

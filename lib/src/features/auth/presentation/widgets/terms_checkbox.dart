import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// Compact "I agree to the Terms & Privacy" row with a custom 18×18 checkbox
/// (Material's `Checkbox` can't be shrunk to the Figma size cleanly).
class TermsCheckbox extends StatelessWidget {
  const TermsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          AnimatedContainer(
            duration: AppDurations.fast,
            width: 18.r,
            height: 18.r,
            decoration: BoxDecoration(
              color: value ? context.colors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(
                color: value ? context.colors.primary : AppColors.inputBorder,
                width: 1.5,
              ),
            ),
            child: value
                ? Icon(Icons.check_rounded, color: Colors.white, size: 13.r)
                : null,
          ),
          SizedBox(width: 8.w),
          Text(
            'auth.agree_terms'.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
              fontSize: 11.5.sp,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// iOS-style pill switch matching the Figma permission toggles.
///
/// The app's Material `Switch` theme renders an outlined thumb; the design
/// wants a solid white thumb on a filled track, so this is a small bespoke
/// control rather than a restyled `Switch`.
class PillToggle extends StatelessWidget {
  const PillToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: AppCurves.standard,
        width: 46.w,
        height: 27.h,
        padding: EdgeInsets.all(3.r),
        decoration: BoxDecoration(
          color: value
              ? context.colors.primary
              : context.colors.outlineVariant,
          borderRadius: AppBorders.full,
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 21.r,
          height: 21.r,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

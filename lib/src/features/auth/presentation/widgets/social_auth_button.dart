import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// A provider sign-in button.
///
/// - [dark] `false` → white fill with a hairline border (Google).
/// - [dark] `true`  → near-black fill (Apple).
/// - [label] `null` → icon only (register uses two of these side by side);
///   otherwise the icon sits left of the label (login stacks full-width ones).
class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({
    super.key,
    required this.asset,
    required this.dark,
    this.label,
    this.onPressed,
  });

  final String asset;
  final bool dark;
  final String? label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final background =
        dark ? context.colors.onSurface : context.colors.surfaceContainerLowest;
    final foreground = dark ? Colors.white : context.colors.onSurface;
    final iconSize = dark ? 16.r : 17.r;

    return SizedBox(
      height: 45.h,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: background,
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
            side: dark
                ? BorderSide.none
                : const BorderSide(color: AppColors.inputBorder),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(asset, width: iconSize, height: iconSize),
            if (label != null) ...[
              SizedBox(width: 10.w),
              Text(
                label!,
                style: context.textTheme.titleSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import '../../imports/core_imports.dart';
import '../../imports/packages_imports.dart';

/// The app's signature call-to-action: an emerald gradient pill with a
/// coloured glow beneath it.
///
/// [AppButton] covers the flat/outline/ghost variants; this one exists
/// separately because the gradient fill and glow cannot be expressed through
/// a Material `ButtonStyle`.
///
/// ```dart
/// AppGradientButton(label: 'auth.sign_in'.tr(), onPressed: _submit)
/// ```
class AppGradientButton extends StatelessWidget {
  const AppGradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.gradient = AppGradients.primaryButton,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    return Opacity(
      opacity: isDisabled && !isLoading ? 0.6 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: AppBorders.button,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.6),
              offset: Offset(0, 12.h),
              blurRadius: 22.r,
              spreadRadius: -8.r,
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 49.h,
          child: TextButton(
            onPressed: isDisabled ? null : onPressed,
            style: TextButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: AppBorders.button,
              ),
            ),
            child: isLoading
                ? SizedBox(
                    width: 20.r,
                    height: 20.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

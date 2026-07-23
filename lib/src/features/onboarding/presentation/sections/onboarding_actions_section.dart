import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// Bottom call-to-action block.
///
/// The first slide offers "Get Started" plus a login shortcut; the remaining
/// slides show only "Continue", so the primary button slides down as the
/// secondary one leaves. [AnimatedSize] keeps that transition smooth.
class OnboardingActionsSection extends StatelessWidget {
  const OnboardingActionsSection({
    super.key,
    required this.isFirstSlide,
    required this.onPrimaryPressed,
    required this.onLoginPressed,
  });

  final bool isFirstSlide;
  final VoidCallback onPrimaryPressed;
  final VoidCallback onLoginPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 22.w),
      child: AnimatedSize(
        duration: AppDurations.normal,
        curve: AppCurves.standard,
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppGradientButton(
              label: isFirstSlide
                  ? 'shared.get_started'.tr()
                  : 'shared.continue_action'.tr(),
              onPressed: onPrimaryPressed,
            ),
            if (isFirstSlide) ...[
              SizedBox(height: 10.h),
              SizedBox(
                width: double.infinity,
                height: 49.h,
                child: TextButton(
                  onPressed: onLoginPressed,
                  child: Text(
                    'onboarding.already_have_account'.tr(),
                    style: context.textTheme.titleSmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

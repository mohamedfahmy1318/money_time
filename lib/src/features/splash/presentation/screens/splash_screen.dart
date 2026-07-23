import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/splash/presentation/widgets/splash_logo.dart';

/// Branded launch screen shown while [SessionCubit] resolves the session.
///
/// `SessionListenerWrapper` navigates away (home / onboarding) as soon as the
/// session status settles, so this screen never needs its own timer.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Letter-spacing is a Latin typographic device — applying it to Arabic
    // would break the cursive joins, so it is dropped in RTL.
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.splash),
        child: Stack(
          children: [
            Positioned(
              top: -90.r,
              right: -90.r,
              child: _GlowCircle(size: 300.r, opacity: 0.08),
            ),
            Positioned(
              bottom: -70.r,
              left: -70.r,
              child: _GlowCircle(size: 220.r, opacity: 0.06),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SplashLogo(),
                  SizedBox(height: 20.h),
                  Text(
                    'app_name'.tr(),
                    style: context.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 30.sp,
                      letterSpacing: isRtl ? null : -0.6,
                    ),
                  ),
                  SizedBox(height: 9.h),
                  Text(
                    'splash.tagline'.tr(),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: AppColors.onPrimaryMuted,
                      fontSize: 13.sp,
                      letterSpacing: isRtl ? null : 2.08,
                    ),
                  ),
                  SizedBox(height: 34.h),
                  const _LoadingDots(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          width: 8.r,
          height: 8.r,
          margin: EdgeInsets.symmetric(horizontal: 3.5.r),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(4.r),
          ),
        )
            .animate(
              onPlay: (controller) => controller.repeat(),
              delay: Duration(milliseconds: index * 180),
            )
            .fadeIn(duration: const Duration(milliseconds: 400))
            .then()
            .fadeOut(duration: const Duration(milliseconds: 400));
      }),
    );
  }
}

import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/onboarding/presentation/models/onboarding_slide.dart';

/// A single onboarding page: illustration, title, supporting copy.
class OnboardingSlideView extends StatelessWidget {
  const OnboardingSlideView({super.key, required this.slide});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SvgPicture.asset(
          slide.illustration,
          width: 170.w,
          height: 150.h,
        ),
        SizedBox(height: 24.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 22.w),
          child: Text(
            slide.title,
            textAlign: TextAlign.center,
            style: context.textTheme.headlineSmall?.copyWith(
              color: context.colors.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 25.sp,
              letterSpacing: -0.5,
            ),
          ),
        ),
        SizedBox(height: 13.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
              fontSize: 14.sp,
              height: 21.7 / 14,
            ),
          ),
        ),
      ],
    );
  }
}

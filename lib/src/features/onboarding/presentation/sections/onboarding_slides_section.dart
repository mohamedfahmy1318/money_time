import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/onboarding/presentation/models/onboarding_slide.dart';
import 'package:mony_time/src/features/onboarding/presentation/widgets/onboarding_slide_view.dart';

/// Swipeable slides plus the page indicator beneath them.
///
/// The slide area is a fixed height so the indicator keeps a constant
/// position; in Figma it drifts a little between pages purely because the
/// body copy runs to two lines on one of them.
class OnboardingSlidesSection extends StatelessWidget {
  const OnboardingSlidesSection({
    super.key,
    required this.controller,
    required this.slides,
    required this.onPageChanged,
  });

  final PageController controller;
  final List<OnboardingSlide> slides;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 28.h),
        SizedBox(
          height: 290.h,
          child: PageView.builder(
            controller: controller,
            itemCount: slides.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) =>
                OnboardingSlideView(slide: slides[index]),
          ),
        ),
        SizedBox(height: 36.h),
        SmoothPageIndicator(
          controller: controller,
          count: slides.length,
          effect: ExpandingDotsEffect(
            dotWidth: 8.r,
            dotHeight: 8.r,
            spacing: 6.r,
            radius: 4.r,
            expansionFactor: 2.75,
            activeDotColor: context.colors.primary,
            dotColor: context.colors.outlineVariant,
          ),
        ),
      ],
    );
  }
}

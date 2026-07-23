import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/onboarding/presentation/models/onboarding_slide.dart';
import 'package:mony_time/src/features/onboarding/presentation/sections/onboarding_actions_section.dart';
import 'package:mony_time/src/features/onboarding/presentation/sections/onboarding_slides_section.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  late final List<OnboardingSlide> _slides = OnboardingSlide.all();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Advances through the tour; the last slide hands off to first-run setup.
  void _onPrimaryPressed() {
    if (_index == _slides.length - 1) {
      context.go(AppRoutes.language);
      return;
    }
    _pageController.nextPage(
      duration: AppDurations.normal,
      curve: AppCurves.standard,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OnboardingSlidesSection(
              controller: _pageController,
              slides: _slides,
              onPageChanged: (index) => setState(() => _index = index),
            ),
            const Spacer(),
            OnboardingActionsSection(
              isFirstSlide: _index == 0,
              onPrimaryPressed: _onPrimaryPressed,
              onLoginPressed: () => context.go(AppRoutes.login),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

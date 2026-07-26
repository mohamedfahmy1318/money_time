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

  /// Advances through the tour; the last slide drops the guest onto home.
  void _onPrimaryPressed() {
    if (_index == _slides.length - 1) {
      _finish(AppRoutes.home);
      return;
    }
    _pageController.nextPage(
      duration: AppDurations.normal,
      curve: AppCurves.standard,
    );
  }

  /// Marks first-run done and navigates. Home enters guest mode; login lets the
  /// user sign in straight away.
  Future<void> _finish(String route) async {
    await AppPrefs.completeOnboarding();
    if (!mounted) return;
    context.go(route);
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
              onLoginPressed: () => _finish(AppRoutes.login),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

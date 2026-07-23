import 'package:mony_time/src/imports/core_imports.dart';

/// Static content for one onboarding page.
///
/// Onboarding has no data or domain layer — nothing here is fetched or
/// persisted — so the slide list lives entirely in the presentation layer.
class OnboardingSlide {
  const OnboardingSlide({
    required this.illustration,
    required this.title,
    required this.subtitle,
  });

  final String illustration;
  final String title;
  final String subtitle;

  /// The three slides, in order, as defined in the Figma flow.
  static List<OnboardingSlide> all() => [
        OnboardingSlide(
          illustration: AppAssets.onboardingTrack,
          title: 'onboarding.track_title'.tr(),
          subtitle: 'onboarding.track_subtitle'.tr(),
        ),
        OnboardingSlide(
          illustration: AppAssets.onboardingBudget,
          title: 'onboarding.budget_title'.tr(),
          subtitle: 'onboarding.budget_subtitle'.tr(),
        ),
        OnboardingSlide(
          illustration: AppAssets.onboardingGoals,
          title: 'onboarding.goals_title'.tr(),
          subtitle: 'onboarding.goals_subtitle'.tr(),
        ),
      ];
}

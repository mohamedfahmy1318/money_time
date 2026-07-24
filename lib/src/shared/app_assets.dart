class AppAssets {
  AppAssets._();

  static const String _basePath = 'assets';
  static const String _iconsPath = '$_basePath/icons';
  static const String _imagesPath = '$_basePath/images';

  // Social icons
  static const String googleIcon = '$_iconsPath/google.svg';
  static const String googleColorIcon = '$_iconsPath/google_color.svg';
  static const String facebookIcon = '$_iconsPath/facebook.svg';
  static const String appleIcon = '$_iconsPath/apple.svg';

  // Brand
  static const String logo = '$_imagesPath/logo_money_time.svg';
  static const String logoMarkDark = '$_imagesPath/logo_mark_dark.svg';

  // Onboarding illustrations
  static const String onboardingTrack = '$_imagesPath/onboarding_track.svg';
  static const String onboardingBudget = '$_imagesPath/onboarding_budget.svg';
  static const String onboardingGoals = '$_imagesPath/onboarding_goals.svg';

  // Welcome (post-auth) illustrations
  static const String welcomeShortcuts = '$_imagesPath/welcome_shortcuts.svg';
  static const String welcomeSuccess = '$_imagesPath/welcome_success.svg';
}

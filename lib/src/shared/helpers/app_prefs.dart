import 'package:mony_time/src/services/services.dart';

/// Typed access to the handful of first-run preferences kept in
/// [StorageService]. Keeps the raw string keys in one place.
abstract final class AppPrefs {
  AppPrefs._();

  static const String _onboardingCompletedKey = 'onboarding_completed';

  /// True once the user has been through the language + onboarding first-run
  /// flow. Guests that have completed it land straight on home.
  static bool get onboardingCompleted =>
      StorageService.instance.getBool(_onboardingCompletedKey) ?? false;

  static Future<void> completeOnboarding() =>
      StorageService.instance.setBool(_onboardingCompletedKey, true);
}

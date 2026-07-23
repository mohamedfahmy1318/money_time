import 'package:flutter/widgets.dart';

/// One selectable language on the language-picker screen.
///
/// This is presentation-only data (no domain/data layer) — the first-run
/// setup flow just records preferences. [locale] is non-null only for
/// languages the app actually ships translations for, so an unsupported
/// pick can be shown without pretending it will switch the UI.
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.name,
    required this.flag,
    this.locale,
  });

  final String code;
  final String name;
  final String flag;
  final Locale? locale;

  bool get isSupported => locale != null;

  /// Every language shown in the Figma list, in order. Only English and
  /// Arabic are wired to real locales today; the rest are display-only until
  /// their translations exist.
  static const List<AppLanguage> values = [
    AppLanguage(code: 'en', name: 'English', flag: '🇬🇧', locale: Locale('en')),
    AppLanguage(code: 'ar', name: 'العربية', flag: '🇸🇦', locale: Locale('ar')),
    AppLanguage(code: 'fr', name: 'Français', flag: '🇫🇷'),
    AppLanguage(code: 'de', name: 'Deutsch', flag: '🇩🇪'),
    AppLanguage(code: 'es', name: 'Español', flag: '🇪🇸'),
    AppLanguage(code: 'it', name: 'Italiano', flag: '🇮🇹'),
    AppLanguage(code: 'pt', name: 'Português', flag: '🇵🇹'),
    AppLanguage(code: 'tr', name: 'Türkçe', flag: '🇹🇷'),
    AppLanguage(code: 'ru', name: 'Русский', flag: '🇷🇺'),
    AppLanguage(code: 'uk', name: 'Українська', flag: '🇺🇦'),
  ];

  /// The entry matching [code], or English as a fallback.
  static AppLanguage byCode(String code) {
    return values.firstWhere(
      (l) => l.code == code,
      orElse: () => values.first,
    );
  }
}

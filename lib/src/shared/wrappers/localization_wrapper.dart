import '../../imports/core_imports.dart';

/// A wrapper to initialize [EasyLocalization] with supported locales.
class LocalizationWrapper extends StatelessWidget {
  final Widget child;

  const LocalizationWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      // Use each language's CLDR plural rules — Arabic needs its few/many
      // forms (٣ رسائل vs ١١ رسالة), which the default fallback never picks.
      ignorePluralRules: false,
      child: child,
    );
  }
}

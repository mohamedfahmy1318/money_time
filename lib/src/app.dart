import 'package:mony_time/src/imports/core_imports.dart';

import 'package:mony_time/src/config/api/api_session.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final current = _buildMaterialApp(context);
    return ScreenUtilWrapper(child: current);
  }

  Widget _buildMaterialApp(BuildContext context) {
    // EasyLocalization rebuilds App on every locale change: keep the API's
    // Accept-Language (translated errors, category labels) on the UI language.
    ApiSession.instance.language = context.locale.languageCode;

    return MaterialApp.router(
      title: 'mony_time',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(primaryColorHex: '#10B981'),
      darkTheme: buildDarkTheme(primaryColorHex: '#10B981'),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      builder: (context, child) {
        Widget current = child!;
        current = SkeletonWrapper(child: current);
        current = SessionListenerWrapper(child: current);
        return current;
      },
    );
  }
}
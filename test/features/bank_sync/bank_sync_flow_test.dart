import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mony_time/src/config/app_config.dart';
import 'package:mony_time/src/features/auth/domain/entities/user.dart';
import 'package:mony_time/src/features/auth/presentation/cubits/session_cubit.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_link.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/presentation/cubits/bank_sync_cubit.dart';
import 'package:mony_time/src/features/transactions/presentation/cubits/transactions_cubit.dart';
import 'package:mony_time/src/routing/app_router.dart';
import 'package:mony_time/src/routing/app_routes.dart';
import 'package:mony_time/src/shared/wrappers/state_wrapper.dart';
import 'package:mony_time/src/theme/theme.dart';

/// Pumps the real app shell (app-wide cubits, router, theme, ScreenUtil) at
/// the Figma artboard size in [locale].
Future<void> _pumpApp(WidgetTester tester, Locale locale) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(298 * 2, 672 * 2);
  addTearDown(tester.view.reset);

  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: locale,
        saveLocale: false,
        ignorePluralRules: false,
        child: StateWrapper(
          child: Builder(
            builder: (context) => ScreenUtilInit(
              designSize: const Size(298, 672),
              minTextAdapt: true,
              builder: (_, __) => MaterialApp.router(
                theme: buildLightTheme(primaryColorHex: '#10B981'),
                routerConfig: appRouter,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
              ),
            ),
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  await _settle(tester);
}

/// Lets the mock datasources' delays elapse and animations finish.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
}

T _read<T extends StateStreamableSource<Object?>>(WidgetTester tester) =>
    tester.element(find.byType(Navigator).first).read<T>();

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('ar');
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost');
    await AppConfig.init();
    // Real glyph metrics — the default test font's square glyphs would report
    // overflows that can't happen on a device.
    final roboto = FontLoader('Roboto');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      roboto.addFont(rootBundle.load('assets/fonts/Roboto-$weight.ttf'));
    }
    await roboto.load();
  });

  testWidgets('connect a bank, then add a clear message from the inbox',
      (tester) async {
    await _pumpApp(tester, const Locale('en'));
    // Cubits are created lazily: let the session's startup check resolve
    // first, or it lands after — and overwrites — the signed-in user.
    final session = _read<SessionCubit>(tester);
    await _settle(tester);
    session.setUser(const AppUser(id: 'u1', email: 'user@example.com'));

    appRouter.go(AppRoutes.bankLink);
    await _settle(tester);
    expect(find.text('Connect my bank'), findsOneWidget);

    await tester.tap(find.text('Connect my bank'));
    await _settle(tester);

    // Step 1 — banks. Continue stays disabled until one is picked.
    await tester.tap(find.text('CIB').first);
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await _settle(tester);

    // Step 2 — the test platform is Android, so SMS access.
    expect(find.text('What we never read'.toUpperCase()), findsOneWidget);
    await tester.tap(find.text('Allow SMS access').last);
    await _settle(tester);

    // Step 3 — import mode, then connect.
    await tester.tap(find.text('Finish setup'));
    await _settle(tester);
    expect(find.text('Bank messages connected'), findsOneWidget);

    final bankSync = _read<BankSyncCubit>(tester);
    expect(bankSync.state.link.isConnected, isTrue);
    expect(bankSync.state.link.method, BankLinkMethod.sms);
    expect(bankSync.state.link.bankIds, ['cib']);

    // CIB seeds: one clear purchase and one that needs attention to review,
    // an OTP filed as ignored.
    expect(bankSync.state.pending, hasLength(2));
    expect(bankSync.state.pendingConfident, hasLength(1));
    expect(
      bankSync.state.ignored.where((m) => !m.isTransaction),
      isNotEmpty,
    );

    await tester.tap(find.text('Review 2 messages'));
    await _settle(tester);

    final before = _read<TransactionsCubit>(tester).state.transactions.length;
    await tester.tap(find.text('Add 1 clear message'));
    await _settle(tester);

    final transactions = _read<TransactionsCubit>(tester).state.transactions;
    expect(transactions, hasLength(before + 1));
    final imported = transactions.firstWhere((t) => t.isAuto && t.note == 'Carrefour Maadi');
    expect(imported.amount, 245.5);
    expect(imported.source, 'CIB •• 4821');
    expect(imported.categoryLabel, 'Groceries');

    final carrefour = bankSync.state.messages
        .firstWhere((m) => m.parsed?.merchant == 'Carrefour Maadi');
    expect(carrefour.status, BankMessageStatus.imported);
    expect(bankSync.state.pending, hasLength(1));
  });

  testWidgets('every bank-sync screen lays out in Arabic without overflow',
      (tester) async {
    await _pumpApp(tester, const Locale('ar'));

    final bankSync = _read<BankSyncCubit>(tester);
    if (!bankSync.state.isConnected) {
      bankSync.connect(
        method: BankLinkMethod.shortcuts,
        bankIds: const ['cib', 'nbe', 'bm', 'qnb', 'instapay'],
        mode: ImportMode.review,
      );
      await _settle(tester);
    }

    for (final route in [
      AppRoutes.bankLink,
      AppRoutes.bankInbox,
      AppRoutes.bankLinkSetup,
      AppRoutes.home,
    ]) {
      appRouter.go(route);
      await _settle(tester);
    }

    for (final message in bankSync.state.messages.take(4)) {
      appRouter.go(AppRoutes.bankMessage, extra: message);
      await _settle(tester);
    }
    // Any RenderFlex overflow above would already have failed the test.
    expect(tester.takeException(), isNull);
  });
}

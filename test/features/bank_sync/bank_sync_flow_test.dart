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
import 'package:mony_time/src/features/bank_sync/bank_sync_di.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_link.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/presentation/cubits/bank_sync_cubit.dart';
import 'package:mony_time/src/features/transactions/presentation/cubits/transactions_cubit.dart';
import 'package:mony_time/src/routing/app_router.dart';
import 'package:mony_time/src/routing/app_routes.dart';
import 'package:mony_time/src/shared/enums/transaction_type.dart';
import 'package:mony_time/src/shared/wrappers/state_wrapper.dart';
import 'package:mony_time/src/theme/theme.dart';

import 'fake_bank_sync_repository.dart';

/// Pumps the real app shell (app-wide cubits, router, theme, ScreenUtil) at
/// the Figma artboard size in [locale]. The bank repository is a fake; the
/// rest of the app runs as shipped.
Future<void> _pumpApp(WidgetTester tester, Locale locale) async {
  // The router is a singleton: start every test from home, not from the
  // previous test's last route (whose `extra` is gone).
  appRouter.go(AppRoutes.home);
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

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

T _read<T extends StateStreamableSource<Object?>>(WidgetTester tester) =>
    tester.element(find.byType(Navigator).first).read<T>();

/// Signs in (cubits are lazy: let the session's startup check resolve first,
/// or it lands after — and overwrites — the user) and loads the inbox, as
/// `SessionListenerWrapper` does in the app.
Future<BankSyncCubit> _signIn(WidgetTester tester) async {
  final session = _read<SessionCubit>(tester);
  await _settle(tester);
  session.setUser(const AppUser(id: 'u1', email: 'user@example.com'));
  final bankSync = _read<BankSyncCubit>(tester)..load();
  await _settle(tester);
  return bankSync;
}

void main() {
  late FakeBankSyncRepository repo;

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

  setUp(() {
    repo = FakeBankSyncRepository();
    BankSyncDi.repository = repo;
    // The user grants SMS access when asked.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (call) async => switch (call.method) {
        'checkPermissionStatus' => 0,
        'requestPermissions' => {
            for (final p in call.arguments as List<Object?>) p as int: 1,
          },
        _ => null,
      },
    );
  });

  testWidgets(
      'connect → SMS access → 30-day import → add clear messages, mirrored '
      'into the ledger', (tester) async {
    await _pumpApp(tester, const Locale('en'));
    final bankSync = await _signIn(tester);

    appRouter.go(AppRoutes.bankLink);
    await _settle(tester);
    await tester.tap(find.text('Connect my bank'));
    await _settle(tester);

    // Step 1 — banks. Continue stays disabled until one is picked.
    await tester.tap(find.text('CIB').first);
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await _settle(tester);

    // Step 2 — Android: the permission is asked here, and only here.
    await tester.tap(find.text('Allow SMS access').last);
    await _settle(tester);

    // Step 3 — connect once, then the history upload.
    await tester.tap(find.text('Finish setup'));
    await _settle(tester);

    expect(repo.calls, containsAllInOrder(['connect', 'importRecentHistory']));
    expect(find.text('Bank messages connected'), findsOneWidget);
    expect(
      find.text('We found 2 recent messages ready to review.'),
      findsOneWidget,
    );
    expect(bankSync.state.link.bankIds, ['cib']);
    expect(bankSync.state.pending, hasLength(2));
    expect(bankSync.state.pendingConfident, hasLength(1));

    await tester.tap(find.text('Review 2 messages'));
    final ledgerCubit = _read<TransactionsCubit>(tester);
    await _settle(tester);

    final before = ledgerCubit.state.transactions.length;
    await tester.tap(find.text('Add 1 clear message'));
    await _settle(tester);

    expect(repo.calls, contains('importMessages'));
    final ledger = _read<TransactionsCubit>(tester).state.transactions;
    expect(ledger, hasLength(before + 1));
    final added = ledger.firstWhere((t) => t.id == 'txn-msg-1');
    expect(added.amount, 245.5);
    expect(added.isAuto, isTrue);
    expect(bankSync.state.pending, hasLength(1));
    expect(bankSync.state.imported.items.single.id, 'msg-1');
  });

  testWidgets('review screen sends only the fields the user changed',
      (tester) async {
    repo
      ..link = const BankLink(
        isConnected: true,
        method: BankLinkMethod.sms,
        bankIds: ['cib'],
      )
      ..seedInbox();
    await _pumpApp(tester, const Locale('en'));
    final bankSync = await _signIn(tester);

    final unsure = bankSync.state.pending.firstWhere((m) => m.needsAttention);
    appRouter.go(AppRoutes.bankMessage, extra: unsure);
    await _settle(tester);
    expect(find.text('Please double-check this one'), findsOneWidget);

    await tester.tap(find.text('Income'));
    await _settle(tester);
    expect(find.text('Automatic'), findsOneWidget);

    await tester.tap(find.text('Add transaction'));
    await _settle(tester);

    expect(repo.lastOverrides?.type, TransactionType.income);
    expect(repo.lastOverrides?.amount, isNull);
    expect(repo.lastOverrides?.categoryId, isNull);
    expect(repo.lastOverrides?.note, isNull);
    expect(
      repo.messages.firstWhere((m) => m.id == unsure.id).status,
      BankMessageStatus.imported,
    );
  });

  testWidgets('ignore moves a card to Ignored and restore brings it back',
      (tester) async {
    repo
      ..link = const BankLink(
        isConnected: true,
        method: BankLinkMethod.sms,
        bankIds: ['cib'],
      )
      ..seedInbox();
    await _pumpApp(tester, const Locale('en'));
    final bankSync = await _signIn(tester);

    appRouter.go(AppRoutes.bankInbox);
    await _settle(tester);
    await tester.tap(find.text('Ignore').first);
    await _settle(tester);
    expect(bankSync.state.pending, hasLength(1));
    expect(bankSync.state.ignored.items, hasLength(2));

    // The "Message ignored" toast sits over the tabs for two seconds.
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.textContaining('Ignored'));
    await _settle(tester);
    await tester.tap(find.text('Restore').first);
    await _settle(tester);
    expect(bankSync.state.pending, hasLength(2));
    expect(repo.calls.where((c) => c == 'setStatus'), hasLength(2));
  });

  testWidgets('every bank-sync screen lays out in Arabic without overflow',
      (tester) async {
    repo
      ..link = const BankLink(
        isConnected: true,
        method: BankLinkMethod.sms,
        bankIds: ['cib', 'nbe'],
      )
      ..seedInbox();
    await _pumpApp(tester, const Locale('ar'));
    final bankSync = await _signIn(tester);

    for (final route in [
      AppRoutes.bankLink,
      AppRoutes.bankInbox,
      AppRoutes.bankLinkSetup,
      AppRoutes.home,
    ]) {
      appRouter.go(route);
      await _settle(tester);
    }
    for (final message in [
      ...bankSync.state.pending,
      ...bankSync.state.ignored.items
    ]) {
      appRouter.go(AppRoutes.bankMessage, extra: message);
      await _settle(tester);
    }
    // Any RenderFlex overflow above would already have failed the test.
    expect(tester.takeException(), isNull);
  });

  testWidgets('signed-out users only get the public bank catalog',
      (tester) async {
    repo.signedIn = false;
    await _pumpApp(tester, const Locale('en'));
    final bankSync = _read<BankSyncCubit>(tester)..load();
    await _settle(tester);

    expect(bankSync.state.banks, hasLength(3));
    expect(repo.calls, ['getSupportedBanks']);
  });
}

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter app scaffolded by the FlutterInit wizard. Clean Architecture + **Cubit** (not Bloc — no events) + go_router + custom (Dio) backend.

**The Dart package is `mony_time` (no `e`), while the directory is `money_time`.** All internal imports are `package:mony_time/...`. Do not "fix" this mismatch.

Companion docs, all authoritative: [AGENTS.md](AGENTS.md) (architecture boundaries, safe-to-modify map), [DESIGN.md](DESIGN.md) (design system rules), [SETUP.md](SETUP.md) (native/platform/env setup), [architecture.md](architecture.md) (one-paragraph layer summary).

## Commands

```bash
flutter pub get
flutter analyze                 # primary verification gate — must be clean
flutter test
flutter test test/widget_test.dart                    # single file
flutter test --plain-name 'App should build'          # single test by name
flutter run

# After editing assets/translations/*.json:
flutter pub run easy_localization:generate -S assets/translations -O lib/src/core/i18n -o locale_keys.g.dart

# After changing assets/images/splash.png or the splash color:
dart run flutter_native_splash:create --path=flutter_native_splash.yaml
```

No `build_runner` / codegen step exists for this stack — do not add one without cause.

## Known gaps

- `.env` is gitignored and must exist (`main.dart` loads it before `runApp`). It holds `API_BASE_URL`; when unset or not an http URL, `AppConfig.defaultBaseUrl` (production, `https://moneytime.findosystem.com/v1`) is used.
- `analysis_options.yaml` declares the `custom_lint` analyzer plugin, but `custom_lint` is not in `dev_dependencies`.
- `AppConfig.useMockData` now only gates **transactions, budgets, home, reports, categories, profile** (in-memory stubs, reset on restart). **Auth and bank messages are live** against the backend and ignore the flag.

## Architecture

### Startup chain

`main.dart` → `LocalizationWrapper` (EasyLocalization, en/ar) → `StateWrapper` (`MultiBlocProvider`, app-wide cubits — currently only `SessionCubit`) → `App` → `ScreenUtilWrapper` → `MaterialApp.router` → builder wraps `SkeletonWrapper` then `SessionListenerWrapper`.

Ordering is load-bearing: `EasyLocalization.ensureInitialized()` → `dotenv.load()` → `StorageService.init()` → `ApiSession.init()` (device id + stored JWT pair from secure storage) → `AppConfig.init()` (builds the shared `Dio` with the API interceptors) → `runApp`. Native splash is preserved in `main` and removed by `SessionListenerWrapper` once session status resolves.

**App-wide cubits are registered in [lib/src/shared/wrappers/state_wrapper.dart](lib/src/shared/wrappers/state_wrapper.dart)**, not in `main.dart`: `SessionCubit`, `TransactionsCubit`, `BudgetsCubit`, `BankSyncCubit`. Feature-scoped cubits are provided per screen via the feature's DI factory (`BlocProvider(create: (_) => AuthDi.authCubit())`). `SessionListenerWrapper` also drives `BankSyncCubit`: `load()` on sign-in, `signOut()` (disarms native SMS capture) on sign-out, `refresh()` on app resume.

### Live API client — [lib/src/config/api/](lib/src/config/api/)

- `ApiSession` (singleton): per-install device id (`X-Device-Id`, never regenerated on logout), access/refresh tokens in `flutter_secure_storage`, UI language mirrored into `Accept-Language` by `App`. `onSignedOut` fires when the server ends the session.
- `ApiHeadersInterceptor` adds `Accept-Language`, `X-Device-Id`, `X-Platform`, `X-App-Version`. `ApiAuthInterceptor` adds the bearer, refreshes **once, single-flight** on `401 TOKEN_EXPIRED` and retries once; `UNAUTHENTICATED` / rejected refresh → `ApiSession.endSession()`. Public endpoints pass `Options(extra: {kSkipAuth: true})`.
- Errors: `AppErrorHandler.toFailure` reads the server envelope `{error: {code, message, fields, request_id}}` into `ServerFailure(message, code:, status:)`; `message` is server-translated and safe to show, logic branches on `code`. Offline → `NetworkFailure('shared.no_connection')`.
- Mutating bank-sync POSTs send an `Idempotency-Key` (uuid) with a body encoded once; batch chunks keep key + bytes across retries.
- Backend repo and the mobile integration guide live in `~/Herd/moneytime` (`docs/mobile/bank-messages-integration.md`, `docs/api/openapi.json`).

### Feature blueprint — auth is the reference

The auth feature is the template every new feature copies:

```text
lib/src/features/auth/
├── auth_di.dart                     # manual wiring: repo singleton + cubit factories (no DI framework)
├── domain/
│   ├── entities/user.dart           # pure Equatable entity, no JSON
│   ├── repositories/auth_repository.dart   # abstract contract, returns FutureEither<T>
│   └── usecases/login_usecase.dart  # one class per action, single call() delegating to repo
├── data/
│   ├── models/user_model.dart       # extends the entity, adds fromJson/toJson
│   ├── datasources/auth_remote_data_source.dart  # raw Dio calls, THROWS on failure
│   └── repositories/auth_repository_impl.dart    # wraps datasource in runTask() → Either
└── presentation/
    ├── cubits/auth_cubit.dart       # state class + cubit in ONE file; status enum, copyWith
    ├── screens/login_screen.dart    # BlocProvider → thin body composing sections
    ├── sections/login_form_section.dart   # page chunks (form, social row, …)
    └── widgets/password_field.dart  # small reusable feature widgets
```

Layer flow: `screen → cubit → usecase → repository contract → repository impl → datasource → AppConfig.dio`.

Rules baked into this pattern:
- **Cubits emit state only** — never navigate, never toast, never take `BuildContext`. Screens react in a `BlocConsumer`/`BlocListener` (see `_onStateChanged` in [login_screen.dart](lib/src/features/auth/presentation/screens/login_screen.dart)).
- Datasources throw; repositories are the only place that calls `runTask()`. Nothing above the repo sees exceptions.
- Screens own controllers/form keys and stay thin; layout lives in `sections/`; reusable pieces in `widgets/`.
- Wiring is manual and boring: one `<feature>_di.dart` with static factories. No get_it.
- `SessionCubit` (app-wide) resolves session at startup (`GET /me`, falling back to the cached user when offline) and handles logout; after login/signup the screen calls `sessionCubit.setUser(...)` then navigates. It also listens to `AuthRepository.sessionEnded` (server revoked / refresh rejected) and drops to guest.

### Error handling — the `runTask` contract

Everything async that can fail goes through `runTask()` in [lib/src/utils/task_runner.dart](lib/src/utils/task_runner.dart), returning `FutureEither<T>` = `Future<Either<Failure, T>>` (fpdart). It catches, logs via `AppLogger`, and maps to a `Failure`. With `requiresNetwork: true` it short-circuits on no connectivity and shows a global toast itself. Callers consume with `.fold()` / `.flatMap()` / `.map()` — never `try/catch` around a service call, and never let a `DioException` reach a widget.

### Services

[lib/src/services/](lib/src/services/) holds cross-cutting device/platform services (storage, location, media, permissions…), singletons via `ClassName.instance`, exported from [services.dart](lib/src/services/services.dart). **Feature API calls do NOT go here** — they live in the feature's `data/datasources/`. Never pass `BuildContext` into a service — use `rootContext` from [global_navigator.dart](lib/src/routing/global_navigator.dart) (nullable) or `showGlobalToast()`.

### Routing

All routes in [app_router.dart](lib/src/routing/app_router.dart); all paths as constants in [app_routes.dart](lib/src/routing/app_routes.dart). Never hard-code a path string. `SessionListenerWrapper` performs the global authenticated→`home` / unauthenticated→`onboarding` redirect on session status change; per-route guards belong in the router config, not in screens.

First-run flow: `splash → language → onboarding → home (guest)` or `→ login`; after signup: `connect-shortcuts → (bank-link-setup in funnel mode) → all-set`. `SessionListenerWrapper` runs in `MaterialApp.router`'s builder, which sits **above** go_router's `InheritedGoRouter`, so it navigates via the `appRouter` singleton, not `context.go`. Screens reached by both `push` and `go` must use `context.popOrGo(fallback)` for their back affordance — a bare `context.pop()` throws "nothing to pop" when the stack was replaced by `go`.

### Bank messages — [lib/src/features/bank_sync/](lib/src/features/bank_sync/)

Live end to end. Domain entities mirror the API objects (`BankMessage` with `channel`/`transactionId`, `BankSyncSummary`, `BankMessagePage`, `ImportOverrides`, `BulkImportResult`…). The repository also owns this device's **native capture** through `BankCaptureLocalDataSource` (`MethodChannel('money_time/bank_capture')`):
- Android: [android/app/src/main/kotlin/com/money/findo/bankcapture/](android/app/src/main/kotlin/com/money/findo/bankcapture/) — `BankSmsReceiver` (RECEIVE_SMS, filters linked senders, queues with a per-SMS Idempotency-Key) → `IngestWorker` (WorkManager, `POST /bank-sync/ingest` with the `mti_` token, Keystore-encrypted by `TokenCipher`); `SmsInbox` reads the last 30 days (READ_SMS) for the wizard.
- iOS: [ios/Runner/BankCapture.swift](ios/Runner/BankCapture.swift) — token in Keychain, "Log Bank Message" App Intent for the Shortcuts automation. Shortcuts can't filter on the alphanumeric sender ids banks use (only phone numbers), so the automation matches on a keyword (`جنيه`/`EGP`/`جم`/`ج.م`, offered as copy chips in the setup step) and the intent routes locally: `Sender` (bound to Shortcut Input › Sender) decides alone — not a linked bank → skipped silently, never attributed to the `Bank` picker fallback. Undeliverable messages (offline, 5xx, 429, revoked token) wait in `BankCaptureQueue` (Application Support, protected until first unlock, 500 items / 30 days) and go out on the next intent run or `flush` (app open / token re-issue). `BankCaptureStore.tokenStore` is swappable; unit tests in [ios/RunnerTests/RunnerTests.swift](ios/RunnerTests/RunnerTests.swift) stub `URLProtocol` and run with `xcodebuild test -workspace ios/Runner.xcworkspace -scheme Runner -only-testing:RunnerTests` on a booted simulator (the test host has no Keychain entitlement, so that one test skips).
- The ingest token is returned **once** by `POST /bank-sync/link` and goes straight to native storage; Dart never persists it. `ensureCapture` issues one only when nothing is stored (fresh install), stands down when the link captures on the other platform, and when native reports `needsToken` (revoked: another phone of the same platform took over, or the password changed) it reports `CaptureOutcome.revoked` **without re-issuing** — the hub shows "capture paused" and `useThisPhone()` claims it back. Automatic re-issue would make two phones revoke each other forever.
- **Catch-up scan (Android):** on every `ensureCapture` the repository reads the device inbox since a stored high-water mark (`bank_sync.catch_up_ms`, set when capture is armed and after the 30-day scan) and uploads anything the live receiver missed (force-stop, before first unlock after a reboot) as `channel: android_sms` through `/bank-sync/messages/batch`. Never from before the mark, so the past the user didn't ask to scan stays private.
- `BankSyncCubit` guards overlapping work with an epoch counter: reads (`load`/`refresh`/`loadMore`/summary) drop their result when a mutation, a full load or `signOut()` happened meanwhile; mutations apply theirs unless the session ended. Screens use `BankImportFlow` for import/paste/ignore/restore/refresh and react to one-shot `BankSyncAction`s (`statusChanged` with `lastMoved`, `refreshFailed`, `captureMoved`…).
- Native timestamps: `SmsTime.pick` prefers the service-centre time (`date_sent`, shared by receiver and scan for the server's minute-level dedupe) but falls back to the device clock when the SMSC stamps the future (the emulator's modem ignores Cairo DST; carriers can too). `X-App-Version` is read natively at request time, never stored. The two capture prefs files and the secure-storage prefs are excluded from Android backup (`res/xml/backup_rules.xml`, `data_extraction_rules.xml`).
- Backend `Idempotent` middleware answers `409 IDEMPOTENCY_IN_PROGRESS` + `Retry-After` when a replay arrives while the first attempt is still running (lock TTL/wait in `config/money_time.php` `idempotency`); the batch uploader waits it out.
- Imports go only through `/bank-sync/messages/{id}/import` and `/bank-sync/messages/import`, then the created transactions are mirrored into the local (still mock) ledger by `BankImportFlow`.
- The on-device `BankSmsParser` only powers the paste sheet's live preview; the server parses what gets stored.

### Presentation-only features

`onboarding` and `setup` (language / currency / enable-features) have **no domain or data layer** — they only record first-run preferences. They skip cubits too: each screen is a plain `StatefulWidget` with local `setState`, matching the onboarding precedent. Add a cubit only when a screen gains real async work. Language selection is the one live side effect — it calls `context.setLocale` (easy_localization persists it) for the supported locales (en/ar); other languages in the Figma list are display-only until their translations exist.

### Imports — use the barrels

Almost every file starts with one or both of:

```dart
import 'package:mony_time/src/imports/core_imports.dart';    // Flutter SDK, easy_localization, config, routing, services, shared.dart
import 'package:mony_time/src/imports/packages_imports.dart'; // fpdart, bloc, dio, go_router, screenutil, svg, animate, …
```

`imports.dart` re-exports both. `core_imports.dart` pulls in `shared.dart`, which pulls in extensions, utils, enums, widgets, wrappers, and `theme_constants.dart` — so `AppSpacing`, `AppButton`, `context.colors`, `runTask`, `AppLogger` are all available from a single import. Add new public surface to the matching barrel rather than deep-importing across features.

## UI conventions

Read [DESIGN.md](DESIGN.md) in full before writing UI. Highest-leverage rules:

- Theme is seeded from the brand emerald `#10B981` via `ColorScheme.fromSeed` in [theme.dart](lib/src/theme/theme.dart); the roles the Figma design pins down (`primary`, `surface`, `onSurface`, `onSurfaceVariant`, `outlineVariant`) are then `copyWith`-overridden to their exact values. Per-widget themes (buttons, inputs, cards, nav, dialogs…) are already defined — style new UI by using Material widgets and letting the theme apply, never hand-rolled `ThemeData` per screen.
- Color: `context.colors` (ColorScheme) and `context.appColors` (`success` / `warning` / `info` + container variants). No hex literals in widgets. The raw Figma palette lives in [app_colors.dart](lib/src/theme/app_colors.dart) (`AppColors`) with brand sweeps in `AppGradients` — reference those two **only** when defining the theme itself or painting a gradient, never inside a feature widget.
- Type: `context.textTheme`. Font family `Roboto` is applied app-wide; never set `fontFamily:` inline.
- Tokens: `AppSpacing`, `AppBorders`, `AppShadows`, `AppDurations`, `AppCurves`. No magic paddings or `BorderRadius.circular(n)`.
- Strings: `'section.key'.tr()` with keys added to **both** `assets/translations/en.json` and `ar.json`. The app supports Arabic — verify RTL.
- Reusable widgets live in [lib/src/shared/widgets/](lib/src/shared/widgets/) (`AppButton`, `AppGradientButton`, `AppTextField`, `AppCard`, `AppTopBar`, `AppIcon`, `AppLoading`, `AppEmptyState`, `AppErrorWidget`, `CommonImage`, `AppCachedImage`) and are exported via `widgets.dart`. Prefer extending these over new one-off widgets. `AppGradientButton` is the emerald primary CTA (gradient + glow); `AppButton` covers flat/outline/ghost variants. Form validation uses `AppValidators` from [validators.dart](lib/src/shared/helpers/validators.dart) — no inline validator lambdas repeating the same checks.
- Inputs are **hint-based, not floating-label** — the global `InputDecorationTheme` is a white fill with a `#E2E8F0` hairline border and a `#9AA8B8` placeholder (radius 14). Pass `hint:` to `AppTextField`, not `label:`.
- Asset paths go in [app_assets.dart](lib/src/shared/app_assets.dart) as constants.

### ScreenUtil — the baseline is the Figma artboard

`ScreenUtilWrapper` uses **`Size(298, 672)`**, which is the design file's inner screen area (the 320×694 device mockup minus its 11 px bezel). Because the baseline equals the artboard, **every number read off Figma is used verbatim** — a 49 px button is `49.h`, a 25 px title is `25.sp`, a 22 px margin is `22.w`. No conversion math, and no per-screen fudging.

Use `.w` / `.h` / `.r` / `.sp` on numeric literals. `AppSpacing` values are already `.r`-scaled getters — use `AppSpacing.lg` bare, never `AppSpacing.lg.w` (double-scales). ScreenUtil values are runtime, so widgets depending on them cannot be `const`.

### Translating a Figma frame

1. `get_design_context` on the node; `download_assets` (`defaultFormat: svg`) for illustrations.
2. Exported SVGs carry the mockup's ancestors — the gray placeholder rect and the phone-frame rounded rects. **Strip everything down to the inner `<g id="SVG">` group** before committing, or the asset renders a full phone frame.
3. Save to `assets/images/`, register the path in [app_assets.dart](lib/src/shared/app_assets.dart).
4. Prefer flow layout (`Column` + `Spacer`) over the absolute positions Figma emits; take spacing values from the gaps between the absolute boxes.
5. Letter-spacing from Latin text must not be applied in RTL — it breaks Arabic cursive joins. Guard with `Directionality.of(context)` (see [splash_screen.dart](lib/src/features/splash/presentation/screens/splash_screen.dart)).

### Screen pattern

Public screen widget = `BlocProvider` shell; private `_XBody` `StatefulWidget` owns controllers/form key and composes `sections/`. Side effects (toast, navigation) happen only in the `BlocConsumer` listener. See the three auth screens.

## Hard limits

- No second state-management or routing library; no `Dio()` constructed outside `AppConfig`.
- No network/backend calls or business logic inside widget `build()`.
- `domain/` stays pure Dart — no Flutter imports, no imports from `data/`.
- Do not commit `.env`. Do not hand-edit `android/`, `ios/` project config except as SETUP.md prescribes.
- Lints in `analysis_options.yaml` are strict (`prefer_single_quotes`, `prefer_final_locals`, `avoid_print`, `strict-inference`, `strict-raw-types`). Do not disable a rule without an explanatory comment.

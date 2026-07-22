# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter app scaffolded by the FlutterInit wizard. Clean Architecture + bloc + go_router + custom (Dio) backend.

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

## Known pre-existing gaps (fix before first run, not silently)

- **`.env` does not exist.** `main.dart` calls `dotenv.load(fileName: '.env')` before `runApp`, so the app throws on launch until it is created. `AppConfig` reads `API_BASE_URL` (falls back to the literal string `test`).
- **`assets/images/` does not exist** but is declared in `pubspec.yaml`. Both of these are the only two `flutter analyze` warnings; a clean analyze run is otherwise the expected baseline.
- `analysis_options.yaml` declares the `custom_lint` analyzer plugin, but `custom_lint` is not in `dev_dependencies`.

## Architecture

### Startup chain

`main.dart` → `LocalizationWrapper` (EasyLocalization, en/ar) → `StateWrapper` (`MultiBlocProvider`, currently only `SessionBloc`) → `App` → `ScreenUtilWrapper` → `MaterialApp.router` → builder wraps `SkeletonWrapper` then `SessionListenerWrapper`.

Ordering is load-bearing: `EasyLocalization.ensureInitialized()` → `dotenv.load()` → `AppConfig.init()` (builds the shared `Dio` + logging interceptors) → `runApp`. Native splash is preserved in `main` and removed by `SessionListenerWrapper` once session status resolves.

**App-wide blocs are registered in [lib/src/shared/wrappers/state_wrapper.dart](lib/src/shared/wrappers/state_wrapper.dart)**, not in `main.dart`. Feature-scoped blocs (e.g. `AuthBloc`) are provided locally at the screen/route level.

### Layer flow

`presentation (bloc) → domain repository contract → data repository impl → services/<x>_service.dart → AppConfig.dio`

Repositories map raw `Map<String, dynamic>` from services into domain entities. Services never return entities; domain never sees Dio.

### Error handling — the `runTask` contract

Everything async that can fail goes through `runTask()` in [lib/src/utils/task_runner.dart](lib/src/utils/task_runner.dart), returning `FutureEither<T>` = `Future<Either<Failure, T>>` (fpdart). It catches, logs via `AppLogger`, and maps to a `Failure`. With `requiresNetwork: true` it short-circuits on no connectivity and shows a global toast itself. Callers consume with `.fold()` / `.flatMap()` / `.map()` — never `try/catch` around a service call, and never let a `DioException` reach a widget.

### Services

Singletons via `ClassName.instance` (see [auth_service.dart](lib/src/services/auth_service.dart)), exported from [services.dart](lib/src/services/services.dart). Never pass `BuildContext` into a service — use `rootContext` from [global_navigator.dart](lib/src/routing/global_navigator.dart) (nullable; `rootNavigatorKey` is wired to `GoRouter`, not `MaterialApp`) or `showGlobalToast()`.

`AuthService` owns a manual `StreamController` for auth-state changes since the custom backend has no auth stream; `SessionBloc` subscribes to it through the repository.

### Routing

All routes in [app_router.dart](lib/src/routing/app_router.dart); all paths as constants in [app_routes.dart](lib/src/routing/app_routes.dart). Never hard-code a path string. `SessionListenerWrapper` performs the global authenticated→`home` / unauthenticated→`onboarding` redirect on session status change; per-route guards belong in the router config, not in screens.

### Imports — use the barrels

Almost every file starts with one or both of:

```dart
import 'package:mony_time/src/imports/core_imports.dart';    // Flutter SDK, easy_localization, config, routing, services, shared.dart
import 'package:mony_time/src/imports/packages_imports.dart'; // fpdart, bloc, dio, go_router, screenutil, svg, animate, …
```

`imports.dart` re-exports both. `core_imports.dart` pulls in `shared.dart`, which pulls in extensions, utils, enums, widgets, wrappers, and `theme_constants.dart` — so `AppSpacing`, `AppButton`, `context.colors`, `runTask`, `AppLogger` are all available from a single import. Add new public surface to the matching barrel rather than deep-importing across features.

## UI conventions

Read [DESIGN.md](DESIGN.md) in full before writing UI. Highest-leverage rules:

- Theme is seeded from `#94A3B8` via `ColorScheme.fromSeed` in [theme.dart](lib/src/theme/theme.dart), with per-widget themes (buttons, inputs, cards, nav, dialogs…) already defined. Style new UI by using Material widgets and letting the theme apply — do not hand-roll `ThemeData` overrides per screen.
- Color: `context.colors` (ColorScheme) and `context.appColors` (`success` / `warning` / `info` + container variants). No hex literals in widgets.
- Type: `context.textTheme`. Font family `Roboto` is applied app-wide; never set `fontFamily:` inline.
- Tokens: `AppSpacing`, `AppBorders`, `AppShadows`, `AppDurations`, `AppCurves`. No magic paddings or `BorderRadius.circular(n)`.
- Strings: `'section.key'.tr()` with keys added to **both** `assets/translations/en.json` and `ar.json`. The app supports Arabic — verify RTL.
- Reusable widgets live in [lib/src/shared/widgets/](lib/src/shared/widgets/) (`AppButton`, `AppTextField`, `AppCard`, `AppTopBar`, `AppIcon`, `AppLoading`, `AppEmptyState`, `AppErrorWidget`, `CommonImage`, `AppCachedImage`) and are exported via `widgets.dart`. Prefer extending these over new one-off widgets.
- Asset paths go in [app_assets.dart](lib/src/shared/app_assets.dart) as constants.

### ScreenUtil — note the baseline discrepancy

`ScreenUtilWrapper` defaults to **`Size(360, 690)`**, while DESIGN.md documents a 390×844 baseline. When translating a Figma frame, confirm which baseline you are scaling against; if you standardize on the Figma frame size, change the `designSize` default in [screen_util_wrapper.dart](lib/src/shared/wrappers/screen_util_wrapper.dart) once rather than compensating per screen.

Use `.w` / `.h` / `.r` / `.sp` on numeric literals. `AppSpacing` values are already `.r`-scaled getters — existing screens still write `AppSpacing.lg.w`, which double-scales; prefer `AppSpacing.lg` alone in new code. ScreenUtil values are runtime, so widgets depending on them cannot be `const`.

### Screen pattern

Existing screens (see [login_screen.dart](lib/src/features/auth/presentation/screens/login_screen.dart)) split a `StatefulWidget` holding controllers/form key from a private `_XView` `StatelessWidget` that renders. Follow this when a screen owns controllers.

## Deviations to be aware of

`AuthBloc` currently passes `BuildContext` inside events and navigates/toasts from the event handler. This contradicts AGENTS.md ("keep handlers thin", no side-effect navigation from blocs). Do not propagate this pattern into new features — emit state and drive navigation/toasts from `BlocListener` / `BlocConsumer` in the presentation layer.

## Hard limits

- No second state-management or routing library; no `Dio()` constructed outside `AppConfig`.
- No network/backend calls or business logic inside widget `build()`.
- `domain/` stays pure Dart — no Flutter imports, no imports from `data/`.
- Do not commit `.env`. Do not hand-edit `android/`, `ios/` project config except as SETUP.md prescribes.
- Lints in `analysis_options.yaml` are strict (`prefer_single_quotes`, `prefer_final_locals`, `avoid_print`, `strict-inference`, `strict-raw-types`). Do not disable a rule without an explanatory comment.

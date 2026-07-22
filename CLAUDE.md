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

## Known pre-existing gaps (fix before first run, not silently)

- **`.env` does not exist.** `main.dart` calls `dotenv.load(fileName: '.env')` before `runApp`, so the app throws on launch until it is created. `AppConfig` reads `API_BASE_URL` (falls back to the literal string `test`).
- **`assets/images/` does not exist** but is declared in `pubspec.yaml`. Both of these are the only two `flutter analyze` warnings; a clean analyze run is otherwise the expected baseline.
- `analysis_options.yaml` declares the `custom_lint` analyzer plugin, but `custom_lint` is not in `dev_dependencies`.

## Architecture

### Startup chain

`main.dart` → `LocalizationWrapper` (EasyLocalization, en/ar) → `StateWrapper` (`MultiBlocProvider`, app-wide cubits — currently only `SessionCubit`) → `App` → `ScreenUtilWrapper` → `MaterialApp.router` → builder wraps `SkeletonWrapper` then `SessionListenerWrapper`.

Ordering is load-bearing: `EasyLocalization.ensureInitialized()` → `dotenv.load()` → `AppConfig.init()` (builds the shared `Dio` + logging interceptors) → `runApp`. Native splash is preserved in `main` and removed by `SessionListenerWrapper` once session status resolves.

**App-wide cubits are registered in [lib/src/shared/wrappers/state_wrapper.dart](lib/src/shared/wrappers/state_wrapper.dart)**, not in `main.dart`. Feature-scoped cubits are provided per screen via the feature's DI factory (`BlocProvider(create: (_) => AuthDi.authCubit())`).

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
- `SessionCubit` (app-wide) resolves session at startup and handles logout; after login/signup the screen calls `sessionCubit.setUser(...)` then navigates. There is no auth-state stream.

### Error handling — the `runTask` contract

Everything async that can fail goes through `runTask()` in [lib/src/utils/task_runner.dart](lib/src/utils/task_runner.dart), returning `FutureEither<T>` = `Future<Either<Failure, T>>` (fpdart). It catches, logs via `AppLogger`, and maps to a `Failure`. With `requiresNetwork: true` it short-circuits on no connectivity and shows a global toast itself. Callers consume with `.fold()` / `.flatMap()` / `.map()` — never `try/catch` around a service call, and never let a `DioException` reach a widget.

### Services

[lib/src/services/](lib/src/services/) holds cross-cutting device/platform services (storage, location, media, permissions…), singletons via `ClassName.instance`, exported from [services.dart](lib/src/services/services.dart). **Feature API calls do NOT go here** — they live in the feature's `data/datasources/`. Never pass `BuildContext` into a service — use `rootContext` from [global_navigator.dart](lib/src/routing/global_navigator.dart) (nullable) or `showGlobalToast()`.

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
- Reusable widgets live in [lib/src/shared/widgets/](lib/src/shared/widgets/) (`AppButton`, `AppTextField`, `AppCard`, `AppTopBar`, `AppIcon`, `AppLoading`, `AppEmptyState`, `AppErrorWidget`, `CommonImage`, `AppCachedImage`) and are exported via `widgets.dart`. Prefer extending these over new one-off widgets. Form validation uses `AppValidators` from [validators.dart](lib/src/shared/helpers/validators.dart) — no inline validator lambdas repeating the same checks.
- Asset paths go in [app_assets.dart](lib/src/shared/app_assets.dart) as constants.

### ScreenUtil — note the baseline discrepancy

`ScreenUtilWrapper` defaults to **`Size(360, 690)`**, while DESIGN.md documents a 390×844 baseline. When translating a Figma frame, confirm which baseline you are scaling against; if you standardize on the Figma frame size, change the `designSize` default in [screen_util_wrapper.dart](lib/src/shared/wrappers/screen_util_wrapper.dart) once rather than compensating per screen.

Use `.w` / `.h` / `.r` / `.sp` on numeric literals. `AppSpacing` values are already `.r`-scaled getters — use `AppSpacing.lg` bare, never `AppSpacing.lg.w` (double-scales). ScreenUtil values are runtime, so widgets depending on them cannot be `const`.

### Screen pattern

Public screen widget = `BlocProvider` shell; private `_XBody` `StatefulWidget` owns controllers/form key and composes `sections/`. Side effects (toast, navigation) happen only in the `BlocConsumer` listener. See the three auth screens.

## Hard limits

- No second state-management or routing library; no `Dio()` constructed outside `AppConfig`.
- No network/backend calls or business logic inside widget `build()`.
- `domain/` stays pure Dart — no Flutter imports, no imports from `data/`.
- Do not commit `.env`. Do not hand-edit `android/`, `ios/` project config except as SETUP.md prescribes.
- Lints in `analysis_options.yaml` are strict (`prefer_single_quotes`, `prefer_final_locals`, `avoid_print`, `strict-inference`, `strict-raw-types`). Do not disable a rule without an explanatory comment.

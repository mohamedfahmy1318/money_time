// Flutter SDK
export 'package:flutter/material.dart';
export 'package:flutter/cupertino.dart' hide RefreshCallback;
export 'package:flutter/foundation.dart';
export 'package:flutter/services.dart';
export 'package:flutter_native_splash/flutter_native_splash.dart';

export 'package:easy_localization/easy_localization.dart' hide TextDirection, MapExtension;

// Project Core — everything exported through shared.dart (theme, extensions,
// utils, widgets, enums) plus routing and services.
export '../config/app_config.dart';
export '../routing/app_router.dart';
export '../routing/app_routes.dart';
export '../routing/global_navigator.dart';
export '../services/services.dart';
export '../shared/shared.dart';

export '../features/auth/presentation/screens/login_screen.dart';
export '../features/auth/presentation/screens/signup_screen.dart';
export '../features/auth/presentation/screens/forgot_password_screen.dart';
export '../features/home/presentation/screens/main_screen.dart';
export '../features/transactions/presentation/screens/add_transaction_screen.dart';
export '../features/transactions/presentation/screens/transactions_screen.dart';
export '../features/transactions/presentation/screens/transaction_detail_screen.dart';
export '../features/transactions/presentation/screens/transaction_search_screen.dart';
export '../features/transactions/presentation/screens/transaction_filter_screen.dart';
export '../features/budgets/presentation/screens/budget_tab.dart';
export '../features/budgets/presentation/screens/budget_settings_screen.dart';
export '../features/budgets/presentation/screens/budget_edit_screen.dart';
export '../features/categories/presentation/screens/add_category_screen.dart';
export '../features/categories/presentation/screens/category_picker_screen.dart';
export '../features/reports/presentation/screens/reports_tab.dart';
export '../features/reports/presentation/screens/total_stats_screen.dart';
export '../features/profile/presentation/screens/profile_tab.dart';
export '../features/onboarding/presentation/screens/onboarding_page.dart';
export '../features/splash/presentation/screens/splash_screen.dart';

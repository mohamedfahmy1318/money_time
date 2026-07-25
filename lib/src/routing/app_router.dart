import 'package:go_router/go_router.dart';
import 'package:mony_time/src/routing/global_navigator.dart';
import 'package:mony_time/src/routing/app_routes.dart';

import 'package:mony_time/src/features/auth/presentation/screens/login_screen.dart';
import 'package:mony_time/src/features/auth/presentation/screens/signup_screen.dart';
import 'package:mony_time/src/features/auth/presentation/screens/forgot_password_screen.dart';

import 'package:mony_time/src/features/home/presentation/screens/main_screen.dart';
import 'package:mony_time/src/features/onboarding/presentation/screens/onboarding_page.dart';
import 'package:mony_time/src/features/splash/presentation/screens/splash_screen.dart';
import 'package:mony_time/src/features/setup/presentation/screens/language_screen.dart';
import 'package:mony_time/src/features/setup/presentation/screens/currency_screen.dart';
import 'package:mony_time/src/features/setup/presentation/screens/enable_features_screen.dart';
import 'package:mony_time/src/features/welcome/presentation/screens/connect_shortcuts_screen.dart';
import 'package:mony_time/src/features/welcome/presentation/screens/all_set_screen.dart';
import 'package:mony_time/src/features/transactions/domain/entities/transaction.dart';
import 'package:mony_time/src/features/transactions/presentation/models/transaction_filter.dart';
import 'package:mony_time/src/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:mony_time/src/features/transactions/presentation/screens/transaction_detail_screen.dart';
import 'package:mony_time/src/features/transactions/presentation/screens/transaction_filter_screen.dart';
import 'package:mony_time/src/features/transactions/presentation/screens/transaction_search_screen.dart';
import 'package:mony_time/src/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:mony_time/src/features/budgets/domain/entities/budget.dart';
import 'package:mony_time/src/features/budgets/presentation/screens/budget_settings_screen.dart';
import 'package:mony_time/src/features/budgets/presentation/screens/budget_edit_screen.dart';
import 'package:mony_time/src/features/categories/presentation/screens/add_category_screen.dart';
import 'package:mony_time/src/features/categories/presentation/screens/category_picker_screen.dart';
import 'package:mony_time/src/features/reports/presentation/screens/total_stats_screen.dart';
import 'package:mony_time/src/features/auth/domain/entities/user.dart';


final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: AppRoutes.language,
      name: 'language',
      builder: (context, state) => const LanguageScreen(),
    ),
    GoRoute(
      path: AppRoutes.currency,
      name: 'currency',
      builder: (context, state) => const CurrencyScreen(),
    ),
    GoRoute(
      path: AppRoutes.enableFeatures,
      name: 'enableFeatures',
      builder: (context, state) => const EnableFeaturesScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      name: 'signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      name: 'forgotPassword',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.connectShortcuts,
      name: 'connectShortcuts',
      builder: (context, state) =>
          ConnectShortcutsScreen(user: state.extra as AppUser?),
    ),
    GoRoute(
      path: AppRoutes.allSet,
      name: 'allSet',
      builder: (context, state) => AllSetScreen(user: state.extra as AppUser?),
    ),
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const MainScreen(),
    ),
    GoRoute(
      path: AppRoutes.addTransaction,
      name: 'addTransaction',
      builder: (context, state) =>
          AddTransactionScreen(initial: state.extra as Transaction?),
    ),
    GoRoute(
      path: AppRoutes.transactions,
      name: 'transactions',
      builder: (context, state) => const TransactionsScreen(),
    ),
    GoRoute(
      path: AppRoutes.budgetSettings,
      name: 'budgetSettings',
      builder: (context, state) => const BudgetSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.budgetEdit,
      name: 'budgetEdit',
      builder: (context, state) =>
          BudgetEditScreen(budget: state.extra as Budget),
    ),
    GoRoute(
      path: AppRoutes.transactionDetail,
      name: 'transactionDetail',
      builder: (context, state) =>
          TransactionDetailScreen(transaction: state.extra as Transaction),
    ),
    GoRoute(
      path: AppRoutes.transactionsSearch,
      name: 'transactionsSearch',
      builder: (context, state) => const TransactionSearchScreen(),
    ),
    GoRoute(
      path: AppRoutes.transactionsFilter,
      name: 'transactionsFilter',
      builder: (context, state) =>
          TransactionFilterScreen(args: state.extra as FilterScreenArgs),
    ),
    GoRoute(
      path: AppRoutes.categoryPicker,
      name: 'categoryPicker',
      builder: (context, state) =>
          CategoryPickerScreen(selectedLabel: state.extra as String?),
    ),
    GoRoute(
      path: AppRoutes.addCategory,
      name: 'addCategory',
      builder: (context, state) => const AddCategoryScreen(),
    ),
    GoRoute(
      path: AppRoutes.totalStats,
      name: 'totalStats',
      builder: (context, state) => const TotalStatsScreen(),
    ),
  ],
);

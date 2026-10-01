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
import 'package:mony_time/src/features/profile/presentation/screens/personal_info_screen.dart';
import 'package:mony_time/src/features/profile/presentation/screens/settings_screen.dart';
import 'package:mony_time/src/features/profile/presentation/screens/transaction_settings_screen.dart';
import 'package:mony_time/src/features/profile/presentation/screens/recurring_screen.dart';
import 'package:mony_time/src/features/categories/presentation/screens/category_manage_screen.dart';
import 'package:mony_time/src/features/profile/presentation/screens/main_currency_screen.dart';
import 'package:mony_time/src/features/profile/presentation/screens/appearance_screen.dart';
import 'package:mony_time/src/features/profile/presentation/screens/reminder_screen.dart';
import 'package:mony_time/src/features/profile/presentation/screens/notifications_screen.dart';
import 'package:mony_time/src/features/profile/presentation/screens/security_screen.dart';
import 'package:mony_time/src/features/profile/presentation/screens/backup_screen.dart';
import 'package:mony_time/src/shared/enums/transaction_type.dart';
import 'package:mony_time/src/features/auth/domain/entities/user.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/presentation/screens/bank_inbox_screen.dart';
import 'package:mony_time/src/features/bank_sync/presentation/screens/bank_link_screen.dart';
import 'package:mony_time/src/features/bank_sync/presentation/screens/bank_link_setup_screen.dart';
import 'package:mony_time/src/features/bank_sync/presentation/screens/bank_message_screen.dart';
import 'package:mony_time/src/features/auth/presentation/models/auth_gate.dart';

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
      path: AppRoutes.enableFeatures,
      name: 'enableFeatures',
      builder: (context, state) => const EnableFeaturesScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => LoginScreen(gate: state.extra as AuthGate?),
    ),
    GoRoute(
      path: AppRoutes.signup,
      name: 'signup',
      builder: (context, state) =>
          SignupScreen(gate: state.extra as AuthGate?),
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
    GoRoute(
      path: AppRoutes.personalInfo,
      name: 'personalInfo',
      builder: (context, state) => const PersonalInfoScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.transactionSettings,
      name: 'transactionSettings',
      builder: (context, state) => const TransactionSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.recurring,
      name: 'recurring',
      builder: (context, state) => const RecurringScreen(),
    ),
    GoRoute(
      path: AppRoutes.categoryManage,
      name: 'categoryManage',
      builder: (context, state) =>
          CategoryManageScreen(type: state.extra as TransactionType),
    ),
    GoRoute(
      path: AppRoutes.mainCurrency,
      name: 'mainCurrency',
      builder: (context, state) => const MainCurrencyScreen(),
    ),
    GoRoute(
      path: AppRoutes.appearance,
      name: 'appearance',
      builder: (context, state) => const AppearanceScreen(),
    ),
    GoRoute(
      path: AppRoutes.reminder,
      name: 'reminder',
      builder: (context, state) => const ReminderScreen(),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      name: 'notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: AppRoutes.security,
      name: 'security',
      builder: (context, state) => const SecurityScreen(),
    ),
    GoRoute(
      path: AppRoutes.backup,
      name: 'backup',
      builder: (context, state) => const BackupScreen(),
    ),
    GoRoute(
      path: AppRoutes.bankLink,
      name: 'bankLink',
      builder: (context, state) => const BankLinkScreen(),
    ),
    GoRoute(
      path: AppRoutes.bankLinkSetup,
      name: 'bankLinkSetup',
      // extra `true` = opened from the post-signup welcome funnel.
      builder: (context, state) =>
          BankLinkSetupScreen(inFunnel: state.extra == true),
    ),
    GoRoute(
      path: AppRoutes.bankInbox,
      name: 'bankInbox',
      builder: (context, state) => const BankInboxScreen(),
    ),
    GoRoute(
      path: AppRoutes.bankMessage,
      name: 'bankMessage',
      builder: (context, state) =>
          BankMessageScreen(message: state.extra as BankMessage),
    ),
  ],
);

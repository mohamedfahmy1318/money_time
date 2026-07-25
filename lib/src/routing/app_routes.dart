/// Centralized route path constants for GoRouter.
///
/// Use these variables instead of raw strings throughout the app.
/// Example: `context.go(AppRoutes.onboarding)` instead of `context.go('/')`.
abstract final class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String home = '/';
  static const String onboarding = '/onboarding';
  static const String language = '/language';
  static const String currency = '/currency';
  static const String enableFeatures = '/enable-features';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String connectShortcuts = '/connect-shortcuts';
  static const String allSet = '/all-set';
  static const String addTransaction = '/add-transaction';
  static const String transactions = '/transactions';
  static const String transactionDetail = '/transaction-detail';
  static const String transactionsSearch = '/transactions-search';
  static const String transactionsFilter = '/transactions-filter';
  static const String budgetSettings = '/budget-settings';
  static const String budgetEdit = '/budget-edit';
  static const String categoryPicker = '/category-picker';
  static const String addCategory = '/add-category';
  static const String totalStats = '/total-stats';
}

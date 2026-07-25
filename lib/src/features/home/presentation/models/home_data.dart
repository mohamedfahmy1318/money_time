import 'package:mony_time/src/imports/core_imports.dart';

/// A spending category shown as a chip on the dashboard.
class HomeCategory {
  const HomeCategory({
    required this.emoji,
    required this.label,
    required this.tint,
  });

  final String emoji;
  final String label;
  final Color tint;
}

/// The month's budget summary shown in the gradient hero card.
class HomeBudget {
  const HomeBudget({
    required this.month,
    required this.total,
    required this.income,
    required this.spent,
  });

  final String month;
  final String total;
  final String income;
  final String spent;
}

/// Placeholder dashboard content. The recent list and budget income/spent now
/// come live from [TransactionsCubit]; what remains here becomes real data
/// once budgets and category management reach the backend.
abstract final class HomeSampleData {
  /// Monthly budget ceiling shown on the hero card (display form of the
  /// summary view's 5,000 placeholder).
  static const budgetTotal = 'E£ 5,000.00';

  static const categories = <HomeCategory>[
    HomeCategory(emoji: '🍜', label: 'Food', tint: AppColors.tintMint),
    HomeCategory(emoji: '🚕', label: 'Transport', tint: AppColors.tintBlue),
    HomeCategory(emoji: '🛍️', label: 'Shopping', tint: AppColors.tintOrange),
  ];
}

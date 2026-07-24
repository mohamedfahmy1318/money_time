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

/// A single entry in the "Recent" list.
class HomeTransaction {
  const HomeTransaction({
    required this.emoji,
    required this.title,
    required this.date,
    required this.amount,
    required this.isIncome,
  });

  final String emoji;
  final String title;
  final String date;

  /// Unsigned, pre-formatted amount (e.g. `3,200`). The sign and colour are
  /// derived from [isIncome] at render time.
  final String amount;
  final bool isIncome;
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

/// Placeholder dashboard content for the UI phase. Replace with real data once
/// the backend and a home cubit exist.
abstract final class HomeSampleData {
  static const budget = HomeBudget(
    month: 'July',
    total: 'E£ 5,000.00',
    income: 'E£ 5,820',
    spent: 'E£ 2,450',
  );

  static const categories = <HomeCategory>[
    HomeCategory(emoji: '🍜', label: 'Food', tint: AppColors.tintMint),
    HomeCategory(emoji: '🚕', label: 'Transport', tint: AppColors.tintBlue),
    HomeCategory(emoji: '🛍️', label: 'Shopping', tint: AppColors.tintOrange),
  ];

  static const recent = <HomeTransaction>[
    HomeTransaction(
      emoji: '💰',
      title: 'Salary',
      date: 'May 23',
      amount: '3,200',
      isIncome: true,
    ),
    HomeTransaction(
      emoji: '🛒',
      title: 'Groceries',
      date: 'May 23',
      amount: '120.50',
      isIncome: false,
    ),
  ];
}

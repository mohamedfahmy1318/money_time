/// One month's income vs expense (bar chart).
class MonthlyFlow {
  const MonthlyFlow({
    required this.month,
    required this.income,
    required this.expense,
  });

  final String month;
  final double income;
  final double expense;
}

/// A category's spend with its share of the top spender (progress bar).
class CategorySpend {
  const CategorySpend({
    required this.emoji,
    required this.label,
    required this.amount,
    required this.fraction,
  });

  final String emoji;
  final String label;

  /// Pre-formatted, e.g. `E£980`.
  final String amount;

  /// Bar fill, 0..1.
  final double fraction;
}

/// A row in the Note list or the assets list: emoji, title, subtitle, amount.
class ReportEntry {
  const ReportEntry({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  final String emoji;
  final String title;
  final String subtitle;

  /// Pre-formatted, e.g. `−120.50`.
  final String amount;
}

/// Placeholder reports content for the UI phase. Replace with real aggregates
/// once the backend exists — mirrors the [HomeSampleData] convention.
abstract final class ReportSampleData {
  // ── Stats: income vs expense per month ────────────────────────────────────
  static const monthlyFlow = <MonthlyFlow>[
    MonthlyFlow(month: 'Jan', income: 4200, expense: 2600),
    MonthlyFlow(month: 'Feb', income: 3800, expense: 2100),
    MonthlyFlow(month: 'Mar', income: 5100, expense: 3200),
    MonthlyFlow(month: 'Apr', income: 4600, expense: 2400),
    MonthlyFlow(month: 'May', income: 5820, expense: 2450),
    MonthlyFlow(month: 'Jun', income: 5000, expense: 2800),
  ];
  static const incomeTotal = 'E£5,820';
  static const expenseTotal = 'E£2,450';

  // ── Stats: category breakdown ─────────────────────────────────────────────
  static const categorySpend = <CategorySpend>[
    CategorySpend(emoji: '🍜', label: 'Food & Dining', amount: 'E£980', fraction: 0.72),
    CategorySpend(emoji: '🚕', label: 'Transport', amount: 'E£450', fraction: 0.40),
    CategorySpend(emoji: '🛍️', label: 'Shopping', amount: 'E£320', fraction: 0.30),
  ];

  // ── Note: tagged transactions ─────────────────────────────────────────────
  static const noteEntries = <ReportEntry>[
    ReportEntry(emoji: '🛒', title: 'Weekly shop', subtitle: 'Groceries', amount: '−120.50'),
    ReportEntry(emoji: '💡', title: 'May bill', subtitle: 'Electricity', amount: '−210.00'),
    ReportEntry(emoji: '☕', title: 'Morning coffee', subtitle: 'Cash', amount: '−22.00'),
    ReportEntry(emoji: '📱', title: 'Vodafone', subtitle: 'Phone bill', amount: '−45.00'),
  ];

  // ── Total stats: net-worth trend ──────────────────────────────────────────
  static const netWorth = 'E£4,600.00';
  static const netWorthChange = '▲ 8.4% vs last month';
  static const netWorthPoints = <double>[3200, 3500, 3800, 3600, 4200, 4600];
  static const netWorthMonths = <String>['Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'];
  static const assets = ReportEntry(
    emoji: '💹',
    title: 'Assets',
    subtitle: 'Growing steadily',
    amount: 'E£5,850',
  );
}

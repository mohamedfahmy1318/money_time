/// Whether the currency symbol sits before or after the amount.
enum SymbolPosition { front, back }

/// One selectable currency on the currency-picker screen.
class AppCurrency {
  const AppCurrency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
  });

  final String code;
  final String name;
  final String symbol;
  final String flag;

  /// Formats the fixed preview amount (1,000.00) with [symbol] on the chosen
  /// side — the number itself is a static sample, only the symbol moves.
  String previewAmount(SymbolPosition position) {
    const sample = '1,000.00';
    return position == SymbolPosition.front
        ? '$symbol $sample'
        : '$sample $symbol';
  }

  static const List<AppCurrency> values = [
    AppCurrency(code: 'USD', name: 'US Dollar', symbol: r'$', flag: '🇺🇸'),
    AppCurrency(code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺'),
    AppCurrency(code: 'GBP', name: 'Pound', symbol: '£', flag: '🇬🇧'),
    AppCurrency(code: 'SAR', name: 'Saudi Riyal', symbol: 'ر.س', flag: '🇸🇦'),
    AppCurrency(code: 'EGP', name: 'Egyptian Pound', symbol: 'E£', flag: '🇪🇬'),
  ];

  static AppCurrency byCode(String code) {
    return values.firstWhere(
      (c) => c.code == code,
      orElse: () => values.first,
    );
  }
}

import '../../imports/imports.dart';

/// Currency symbol used across the app.
///
/// The currency setup screen is display-only for now; once a selected currency
/// is persisted this becomes a lookup instead of a constant.
const String kCurrencySymbol = 'E£';

/// Overall monthly budget ceiling (home hero, budget tab, summary, reports).
/// Placeholder until budgets become real backend data.
const double kMonthlyBudget = 5000;

/// `3,200` · `120.50` — thousands separators, decimals only when present.
String formatMoney(num value) {
  final abs = value.abs();
  final fixed = abs.toStringAsFixed(abs % 1 == 0 ? 0 : 2);
  final parts = fixed.split('.');
  final whole = formatNumber(int.parse(parts[0]));
  return parts.length > 1 ? '$whole.${parts[1]}' : whole;
}

/// `+3,200` for income, `−120.50` (U+2212) for expense — the signed, coloured
/// amounts on transaction rows.
String signedMoney(num value, {required bool isIncome}) =>
    '${isIncome ? '+' : '−'}${formatMoney(value)}';

/// `E£ 46.50`
String moneyWithSymbol(num value) => '$kCurrencySymbol ${formatMoney(value)}';

/// Locale-aware date patterns pinned by the Figma designs.
abstract final class AppDate {
  AppDate._();

  /// `Fri, 23 May` — day group headers on the transactions list.
  static String dayHeader(DateTime d, String locale) =>
      DateFormat('EEE, d MMM', locale).format(d);

  /// `Fri, 23 May 2026` — transaction detail + add-transaction date row.
  static String fullDate(DateTime d, String locale) =>
      DateFormat('EEE, d MMM yyyy', locale).format(d);

  /// `May 2026` — month stepper.
  static String monthYear(DateTime d, String locale) =>
      DateFormat('MMMM yyyy', locale).format(d);

  /// `May` / `مايو` — home budget card.
  static String monthName(DateTime d, String locale) =>
      DateFormat('MMMM', locale).format(d);

  /// `Jul` — monthly report rows.
  static String monthAbbr(DateTime d, String locale) =>
      DateFormat('MMM', locale).format(d);

  /// `23 May` — search result subtitles, calendar day card titles.
  static String shortDate(DateTime d, String locale) =>
      DateFormat('d MMM', locale).format(d);

  /// `2:32 PM` / `2:32 م`.
  static String time(DateTime d, String locale) =>
      DateFormat('h:mm a', locale).format(d);

  /// `Today · 2:32 PM`, `Yesterday · 9:10 AM`, `21 Sep · 6:04 PM` — bank
  /// message timestamps.
  static String relative(DateTime d, String locale) {
    final day = d.isToday
        ? 'shared.today'.tr()
        : d.isYesterday
            ? 'shared.yesterday'.tr()
            : shortDate(d, locale);
    return '$day · ${time(d, locale)}';
  }
}

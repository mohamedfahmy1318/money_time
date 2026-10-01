import 'package:mony_time/src/shared/enums/transaction_type.dart';

/// A category suggestion for an imported message.
typedef CategoryGuess = ({String emoji, String label});

/// Suggests a category from the merchant / message text using keyword rules
/// tuned for Egyptian merchants. Labels are plain strings like the rest of the
/// category data — they become user categories once that feature is real.
abstract final class MerchantCategories {
  MerchantCategories._();

  static final List<(RegExp, CategoryGuess)> _income = [
    (_rx(r'salary|payroll|راتب|مرتب'), (emoji: '💰', label: 'Salary')),
    (_rx(r'bonus|مكافأة|مكافاة|حافز'), (emoji: '🥇', label: 'Bonus')),
    (_rx(r'refund|reversal|cashback|استرداد|مرتجع'), (emoji: '↩️', label: 'Refund')),
  ];

  static final List<(RegExp, CategoryGuess)> _expense = [
    (
      _rx(r'carrefour|spinneys|seoudi|kazyon|metro market|hyper|gourmet|'
          r'oscar|breadfast|rabbit|كارفور|سعودي|كازيون'),
      (emoji: '🛒', label: 'Groceries'),
    ),
    (
      _rx(r'talabat|elmenus|mcdonald|kfc|pizza|burger|cafe|coffee|starbucks|'
          r'costa|cilantro|restaurant|طلبات|مطعم|كافيه'),
      (emoji: '🍜', label: 'Food'),
    ),
    (
      _rx(r'uber|careem|indrive|swvl|didi|\bmetro\b|fuel|petrol|wataniya|'
          r'total ?energies|\bmobil\b|chillout|اوبر|أوبر|كريم|بنزين'),
      (emoji: '🚕', label: 'Transport'),
    ),
    (
      _rx(r'vodafone|orange|etisalat|e&|\bwe\b|telecom|electric|water|\bgas\b|'
          r'fawry|فوري|فودافون|اورنج|اتصالات|كهرباء|مياه|غاز'),
      (emoji: '💡', label: 'Bills'),
    ),
    (
      _rx(r'pharma|seif|ezaby|hospital|clinic|\blabs?\b|صيدلية|مستشفى|عيادة'),
      (emoji: '💊', label: 'Health'),
    ),
    (
      _rx(r'netflix|spotify|shahid|\bosn\b|anghami|cinema|vox|youtube|'
          r'playstation|steam|سينما|شاهد'),
      (emoji: '🎬', label: 'Culture'),
    ),
    (
      _rx(r'amazon|\bnoon\b|jumia|zara|h&m|lc waikiki|defacto|ikea|b\.?tech|'
          r'\bmall\b|\bstore\b|\bshop\b|نون|جوميا|امازون'),
      (emoji: '🛍️', label: 'Shopping'),
    ),
    (_rx(r'\batm\b|withdraw|سحب'), (emoji: '💵', label: 'Cash')),
    (
      _rx(r'instapay|transfer|تحويل|انستاباي|إنستاباي'),
      (emoji: '🔁', label: 'Transfer'),
    ),
  ];

  static const CategoryGuess _otherIncome = (emoji: '➕', label: 'Other');
  static const CategoryGuess _otherExpense = (emoji: '🧾', label: 'Other');

  /// Matches the [merchant] first (most specific), then the whole message
  /// [body] (catches cues like "salary" or "InstaPay" outside the merchant).
  static CategoryGuess guess({
    required String? merchant,
    required String body,
    required TransactionType type,
  }) {
    final rules = type == TransactionType.income ? _income : _expense;
    for (final text in [if (merchant != null) merchant, body]) {
      for (final (pattern, category) in rules) {
        if (pattern.hasMatch(text)) return category;
      }
    }
    return type == TransactionType.income ? _otherIncome : _otherExpense;
  }

  static RegExp _rx(String pattern) => RegExp(pattern, caseSensitive: false);
}

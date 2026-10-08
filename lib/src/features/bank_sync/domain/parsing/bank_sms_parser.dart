import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/domain/parsing/merchant_categories.dart';
import 'package:mony_time/src/shared/enums/transaction_type.dart';

/// Reads Egyptian bank alert SMS — English and Arabic — into a
/// [ParsedBankSms].
///
/// Pure and synchronous (no I/O) so it runs on-device before anything is
/// stored. Returns `null` for messages that are not transactions: OTP codes,
/// promotions, or text with no amount in it.
abstract final class BankSmsParser {
  BankSmsParser._();

  static ParsedBankSms? parse(String body, {DateTime? receivedAt}) {
    final text = _normalize(body);
    if (text.isEmpty || _isNoise(text)) return null;

    final amounts = _readAmounts(text);
    final amount = amounts.amount;
    if (amount == null || amount <= 0) return null;

    final (type, typeDetected) = _readType(text);
    final merchant = _readMerchant(text);
    final category =
        MerchantCategories.guess(merchant: merchant, body: text, type: type);

    return ParsedBankSms(
      amount: amount,
      type: type,
      categoryEmoji: category.emoji,
      categoryLabel: category.label,
      merchant: merchant,
      cardLast4: _readCard(text),
      balance: amounts.balance,
      occurredAt: _readDate(text, receivedAt ?? DateTime.now()),
      typeDetected: typeDetected,
      currencyDetected: amounts.withCurrency,
    );
  }

  // ── Normalisation ──────────────────────────────────────────────────────────

  /// Arabic-Indic digits → ASCII, dotted currency codes collapsed (so their
  /// dots don't read as sentence ends), whitespace squeezed.
  static String _normalize(String raw) {
    final buffer = StringBuffer();
    for (final rune in raw.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(0x30 + rune - 0x0660);
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(0x30 + rune - 0x06F0);
      } else if (rune == 0x066B) {
        buffer.write('.'); // Arabic decimal separator
      } else if (rune == 0x066C) {
        buffer.write(','); // Arabic thousands separator
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer
        .toString()
        .replaceAll(RegExp(r'\bL\.E\b\.?', caseSensitive: false), 'LE')
        .replaceAll(RegExp(r'ج\.م\.?'), 'جم')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ── Noise (OTP / promotions) ───────────────────────────────────────────────

  static final _otp = RegExp(
    r'\botp\b|one[- ]time|verification code|passcode|\bpin\b|'
    r'كود|رمز|كلمة المرور|كلمة السر|الرقم السري',
    caseSensitive: false,
  );

  static final _promo = RegExp(
    r'\d ?%|\boffer\b|\bpromo|\bwin\b|up to|عرض|اربح|استمتع|خصم \d+ ?%',
    caseSensitive: false,
  );

  /// Something already happened — separates a real alert from an OTP or an
  /// ad that merely mentions an amount.
  static final _completed = RegExp(
    r'charged|debited|credited|deposited|withdrawn|received|\bwas\b|'
    r'has been|تم|خصم|إيداع|ايداع',
    caseSensitive: false,
  );

  static bool _isNoise(String text) =>
      (_otp.hasMatch(text) || _promo.hasMatch(text)) &&
      !_completed.hasMatch(text);

  // ── Amounts ────────────────────────────────────────────────────────────────

  static const _num = r'(\d{1,3}(?:,\d{3})+(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)';
  static const _cur = r'(?:EGP|E£|\bLE\b|جنيه(?:ا|اً)?|جم)';

  static final _currencyAmount =
      RegExp('$_cur ?$_num|$_num ?$_cur', caseSensitive: false);

  /// An amount with no currency next to it ("a transaction of 1,250.00").
  static final _bareAmount = RegExp(
    '(?:amount of|value of|\\bof|بمبلغ|مبلغ|بقيمة) ?$_num',
    caseSensitive: false,
  );

  static final _balanceCue = RegExp(
    r'avail|\bavl\b|\bbal\b|balance|limit|الرصيد|رصيد|المتاح|متاح',
    caseSensitive: false,
  );

  /// The first amount that isn't a balance is the transaction; the first one
  /// preceded (within its clause) by a balance cue is the balance.
  static ({double? amount, double? balance, bool withCurrency}) _readAmounts(
    String text,
  ) {
    double? amount;
    double? balance;
    var previousEnd = 0;

    for (final m in _currencyAmount.allMatches(text)) {
      final value = _toDouble(m.group(1) ?? m.group(2));
      final windowStart = (m.start - 30).clamp(previousEnd, m.start);
      final isBalance =
          _balanceCue.hasMatch(text.substring(windowStart, m.start));
      previousEnd = m.end;
      if (value == null) continue;

      if (isBalance) {
        balance ??= value;
      } else {
        amount ??= value;
      }
    }

    if (amount != null) {
      return (amount: amount, balance: balance, withCurrency: true);
    }

    final bare = _bareAmount.firstMatch(text);
    return (
      amount: _toDouble(bare?.group(1)),
      balance: balance,
      withCurrency: false,
    );
  }

  static double? _toDouble(String? raw) =>
      raw == null ? null : double.tryParse(raw.replaceAll(',', ''));

  // ── Type ───────────────────────────────────────────────────────────────────

  static final _incomeCue = RegExp(
    r'credited|deposit|received|refund|reversal|cashback|salary|payroll|'
    r'transfer(?:red)? from|incoming|إيداع|ايداع|أودع|إضافة|اضافة|أضيف|اضيف|'
    r'استلام|استرداد|راتب|وارد|دائن|إلى حسابكم|الى حسابكم|لحسابكم',
    caseSensitive: false,
  );

  static final _expenseCue = RegExp(
    r'charged|debited|purchase|\bpaid\b|payment (?:of|to|for)|spent|withdraw|'
    r'\bpos\b|خصم|شراء|سحب|دفع|سداد|مدين|من حسابكم|من حسابك|من بطاقتكم|'
    r'من بطاقتك',
    caseSensitive: false,
  );

  static final _transferCue = RegExp(
    r'transfer|\bsent\b|instapay|تحويل|ارسال|إرسال',
    caseSensitive: false,
  );

  /// Whichever cue comes first wins; an outgoing transfer counts as expense.
  /// With no cue at all the type is a guess (`typeDetected == false`).
  static (TransactionType, bool) _readType(String text) {
    final income = _incomeCue.firstMatch(text)?.start;
    final expense = _expenseCue.firstMatch(text)?.start;

    if (income != null && (expense == null || income < expense)) {
      return (TransactionType.income, true);
    }
    if (expense != null || _transferCue.hasMatch(text)) {
      return (TransactionType.expense, true);
    }
    return (TransactionType.expense, false);
  }

  // ── Merchant ───────────────────────────────────────────────────────────────

  static final _merchantEn = RegExp(
    r"\b(?:at|from|to)\s+([A-Za-z0-9][A-Za-z0-9 &'._*\-]{1,40}?)"
    r'(?=\s+(?:on|with|using|via|card|ref|for|dated|at|was|is|has)\b|'
    r'\s*[,;]|\.\s|\.?$)',
    caseSensitive: false,
  );

  // No `\b` here: Dart's word boundary is ASCII-only, so it never fires next
  // to Arabic letters. The lookbehind stops `من` matching inside `ضمن`.
  static final _merchantAr = RegExp(
    r'(?<![ء-ي])(?:لدى|لدي|عند|إلى|الى|لصالح|من)\s+'
    r'([^\d.,،:\n]{2,40}?)'
    r'(?=\s+(?:بتاريخ|يوم|في|رقم|عبر|بقيمة|بمبلغ|من|على)(?:\s|$)|'
    r'\s*[.,،]|$)',
  );

  /// Captures that are the user's own account/card, not a counterparty.
  static final _notMerchant = RegExp(
    r'^(?:your|the|a|an|my)\b|account|\bcard\b|حساب|بطاقة',
    caseSensitive: false,
  );

  static String? _readMerchant(String text) {
    for (final pattern in [_merchantEn, _merchantAr]) {
      for (final m in pattern.allMatches(text)) {
        final candidate = m.group(1)!.trim();
        if (candidate.length < 2 || _notMerchant.hasMatch(candidate)) continue;
        return _tidyMerchant(candidate);
      }
    }
    return null;
  }

  /// `UBER *TRIP` → `Uber Trip`; short all-caps words (`KFC`, `H&M`) stay.
  static String _tidyMerchant(String raw) {
    final cleaned = raw
        .replaceAll('*', ' ')
        .replaceAll(RegExp(r'[\s\-.]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned != cleaned.toUpperCase() ||
        !RegExp('[A-Z]').hasMatch(cleaned)) {
      return cleaned;
    }
    return cleaned
        .split(' ')
        .map(
            (w) => w.length <= 3 ? w : '${w[0]}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  // ── Card ───────────────────────────────────────────────────────────────────

  static final _card = RegExp(
    r'(?:ending(?: with| in)?|card no\.?|acc(?:ount)?(?: no\.?)?|رقم|بطاقة)'
    r'\s*[*xX•]*\s*(\d{4})(?!\d)|[*xX•]{2,}\s*(\d{4})(?!\d)',
    caseSensitive: false,
  );

  static String? _readCard(String text) {
    final m = _card.firstMatch(text);
    return m?.group(1) ?? m?.group(2);
  }

  // ── Date ───────────────────────────────────────────────────────────────────

  static final _numericDate =
      RegExp(r'(?<!\d)(\d{1,2})[/\-](\d{1,2})(?:[/\-](\d{2,4}))?(?!\d)');

  static final _namedDate = RegExp(
    r'(?<!\d)(\d{1,2}) ?(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)'
    r'[A-Z]*(?: ?(\d{4}))?',
    caseSensitive: false,
  );

  static final _time = RegExp(r'(?<!\d)(\d{1,2}):(\d{2})(?!\d)');

  static const _months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  /// Egyptian alerts write day-first (`24/09`, `24/09/2026`, `21SEP`). A
  /// missing year is the one that keeps the date from landing in the future.
  static DateTime? _readDate(String text, DateTime reference) {
    int? day;
    int? month;
    int? year;

    final numeric = _numericDate.firstMatch(text);
    final named = _namedDate.firstMatch(text);
    if (numeric != null) {
      day = int.parse(numeric.group(1)!);
      month = int.parse(numeric.group(2)!);
      year = int.tryParse(numeric.group(3) ?? '');
    } else if (named != null) {
      day = int.parse(named.group(1)!);
      month = _months.indexOf(named.group(2)!.toUpperCase()) + 1;
      year = int.tryParse(named.group(3) ?? '');
    }
    if (day == null || month == null || month < 1 || month > 12) return null;

    final inferredYear = year == null;
    var y = year ?? reference.year;
    if (y < 100) y += 2000;

    var hour = 0;
    var minute = 0;
    final time = _time.firstMatch(text);
    if (time != null) {
      final h = int.parse(time.group(1)!);
      final m = int.parse(time.group(2)!);
      if (h < 24 && m < 60) (hour, minute) = (h, m);
    }

    var date = DateTime(y, month, day, hour, minute);
    if (date.month != month) return null; // e.g. 31/02
    if (inferredYear && date.isAfter(reference.add(const Duration(days: 1)))) {
      date = DateTime(y - 1, month, day, hour, minute);
    }
    return date;
  }
}

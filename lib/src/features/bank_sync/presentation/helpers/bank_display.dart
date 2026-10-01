import 'package:mony_time/src/imports/core_imports.dart';

import 'package:mony_time/src/features/bank_sync/domain/entities/bank.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/transactions/domain/entities/transaction.dart';

final _startsArabic = RegExp(r'^[^A-Za-z\u0600-\u06FF]*[\u0600-\u06FF]');

/// Bank SMS arrive in either script regardless of the app language: lay a
/// message out by its own first strong character.
TextDirection smsDirection(String text) =>
    _startsArabic.hasMatch(text) ? TextDirection.rtl : TextDirection.ltr;

/// `−E£ 245.50` / `+E£ 12,000`. Render it with `TextDirection.ltr` so the
/// sign stays in front of the number inside Arabic layouts.
String signedMoneyWithSymbol(num value, {required bool isIncome}) =>
    '${isIncome ? '+' : '−'}${moneyWithSymbol(value)}';

/// Presentation sugar for [Bank].
extension BankDisplayX on Bank {
  String displayName(BuildContext context) =>
      context.locale.languageCode == 'ar' ? nameAr : name;

  Color get color => Color(brandColor);
}

/// Presentation sugar for [BankMessage]: display strings and the mapping to a
/// [Transaction] on import.
extension BankMessageDisplayX on BankMessage {
  /// Row title — the merchant, else the bank.
  String title(BuildContext context, Bank? bank) =>
      parsed?.merchant ?? bank?.displayName(context) ?? sender;

  /// `CIB •• 4821` — becomes the transaction's source.
  String accountLabel(Bank? bank) {
    final card = parsed?.cardLast4;
    final name = bank?.shortName ?? sender;
    return card == null ? name : '$name •• $card';
  }

  /// When the money moved: the date in the text, keeping the received time
  /// when the text carries only a date for that same day.
  DateTime get occurredAt {
    final written = parsed?.occurredAt;
    if (written == null || written.isSameDay(receivedAt)) return receivedAt;
    return written;
  }

  /// `−E£ 245.50` / `+E£ 12,000`.
  String signedAmount() {
    final p = parsed;
    if (p == null) return '—';
    return signedMoneyWithSymbol(p.amount, isIncome: p.type.isIncome);
  }

  /// The transaction this message imports as. Overrides carry the user's
  /// edits from the review screen.
  Transaction toTransaction(
    Bank? bank, {
    TransactionType? type,
    double? amount,
    String? categoryEmoji,
    String? categoryLabel,
    DateTime? date,
    String? note,
  }) {
    final p = parsed;
    return Transaction(
      id: 'txn-$id',
      type: type ?? p?.type ?? TransactionType.expense,
      amount: amount ?? p?.amount ?? 0,
      categoryEmoji: categoryEmoji ?? p?.categoryEmoji ?? '🧾',
      categoryLabel: categoryLabel ?? p?.categoryLabel ?? 'Other',
      source: accountLabel(bank),
      date: date ?? occurredAt,
      note: note ?? p?.merchant ?? '',
      isAuto: true,
    );
  }
}

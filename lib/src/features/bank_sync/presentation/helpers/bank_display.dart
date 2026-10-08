import 'package:mony_time/src/imports/core_imports.dart';

import 'package:mony_time/src/features/bank_sync/domain/entities/bank.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_sync_results.dart';
import 'package:mony_time/src/features/transactions/domain/entities/transaction.dart';

final _startsArabic = RegExp(r'^[^A-Za-z؀-ۿ]*[؀-ۿ]');

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

/// Presentation sugar for [BankMessage].
extension BankMessageDisplayX on BankMessage {
  /// Row title — the merchant, else the bank.
  String title(BuildContext context, Bank? bank) =>
      parsed?.merchant ?? bank?.displayName(context) ?? sender;

  /// `CIB •• 4821` — the account the server files the transaction under.
  String accountLabel(Bank? bank) {
    final card = parsed?.cardLast4;
    final name = bank?.shortName ?? sender;
    return card == null ? name : '$name •• $card';
  }

  /// `🛒 Groceries`, with a neutral fallback when no category matched.
  String categoryLine() {
    final p = parsed;
    if (p == null) return '';
    return '${p.categoryEmoji ?? '🧾'} ${p.categoryLabel ?? '—'}';
  }

  /// `−E£ 245.50` / `+E£ 12,000`.
  String signedAmount() {
    final p = parsed;
    if (p == null) return '—';
    return signedMoneyWithSymbol(p.amount, isIncome: p.type.isIncome);
  }
}

/// The server's transaction as a ledger row. The ledger is still local, so
/// imports are mirrored into it to show up in Home and Transactions.
extension ImportedTransactionX on ImportedTransaction {
  Transaction toLedgerEntry() => Transaction(
        id: id,
        type: type,
        amount: amount,
        categoryEmoji: categoryEmoji,
        categoryLabel: categoryLabel,
        source: source,
        date: date,
        note: note,
        isAuto: true,
      );
}

/// Sums money in integer piastres so long lists don't drift.
double sumAmounts(Iterable<double> amounts) =>
    amounts.fold<int>(0, (total, a) => total + (a * 100).round()) / 100;

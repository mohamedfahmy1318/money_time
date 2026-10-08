import 'package:equatable/equatable.dart';

import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/shared/enums/transaction_type.dart';

/// One page of an inbox tab (newest first) with its opaque cursor.
class BankMessagePage extends Equatable {
  const BankMessagePage({
    this.items = const [],
    this.nextCursor,
    this.hasMore = false,
  });

  static const empty = BankMessagePage();

  final List<BankMessage> items;
  final String? nextCursor;
  final bool hasMore;

  @override
  List<Object?> get props => [items, nextCursor, hasMore];
}

/// A user category, as offered by the review screen's picker.
class BankCategory extends Equatable {
  const BankCategory({
    required this.id,
    required this.type,
    required this.name,
    required this.emoji,
    this.systemKey,
  });

  final String id;
  final TransactionType type;
  final String name;
  final String emoji;
  final String? systemKey;

  @override
  List<Object?> get props => [id, type, name, emoji, systemKey];
}

/// The review screen's edits. Only what the user changed is sent; anything
/// left `null` keeps the parsed value server-side.
class ImportOverrides extends Equatable {
  const ImportOverrides({
    this.type,
    this.amount,
    this.categoryId,
    this.date,
    this.note,
  });

  static const none = ImportOverrides();

  final TransactionType? type;
  final double? amount;
  final String? categoryId;
  final DateTime? date;

  /// `null` keeps the merchant as the note; `''` stores an empty note.
  final String? note;

  @override
  List<Object?> get props => [type, amount, categoryId, date, note];
}

/// The transaction the server created from a message.
class ImportedTransaction extends Equatable {
  const ImportedTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.categoryEmoji,
    required this.categoryLabel,
    required this.source,
    this.note = '',
    this.bankMessageId,
  });

  final String id;
  final TransactionType type;
  final double amount;
  final DateTime date;
  final String categoryEmoji;
  final String categoryLabel;

  /// The account it landed in (`CIB •• 4821`).
  final String source;
  final String note;
  final String? bankMessageId;

  @override
  List<Object?> get props => [
        id,
        type,
        amount,
        date,
        categoryEmoji,
        categoryLabel,
        source,
        note,
        bankMessageId,
      ];
}

/// A message moved to imported, with the transaction it became.
class BankImportResult extends Equatable {
  const BankImportResult({required this.message, required this.transaction});

  final BankMessage message;
  final ImportedTransaction transaction;

  @override
  List<Object?> get props => [message, transaction];
}

/// Why a bulk import passed over a message.
enum ImportSkipReason { notFound, noParsed, notPending, invalid }

/// The outcome of "Add N clear messages": what was added and what was
/// skipped (already handled elsewhere, no usable category …).
class BulkImportResult extends Equatable {
  const BulkImportResult({this.imported = const [], this.skipped = const {}});

  final List<BankImportResult> imported;

  /// Message id → reason.
  final Map<String, ImportSkipReason> skipped;

  @override
  List<Object?> get props => [imported, skipped];
}

/// A pasted SMS as stored. In automatic mode a confident paste is imported
/// right away and [transaction] is set; [duplicate] means the same SMS was
/// already in the inbox (the stored one is returned).
class SubmittedBankMessage extends Equatable {
  const SubmittedBankMessage({
    required this.message,
    this.transaction,
    this.duplicate = false,
  });

  final BankMessage message;
  final ImportedTransaction? transaction;
  final bool duplicate;

  @override
  List<Object?> get props => [message, transaction, duplicate];
}

/// The 30-day SMS scan's totals across every uploaded batch.
class HistoryScanResult extends Equatable {
  const HistoryScanResult({
    this.found = 0,
    this.created = 0,
    this.duplicates = 0,
    this.rejected = 0,
    this.pendingCreated = 0,
  });

  /// Bank SMS read from the device inbox.
  final int found;
  final int created;
  final int duplicates;
  final int rejected;

  /// New messages now waiting in "To review" (scan never auto-imports).
  final int pendingCreated;

  @override
  List<Object?> get props =>
      [found, created, duplicates, rejected, pendingCreated];
}

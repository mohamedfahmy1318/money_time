import 'package:equatable/equatable.dart';

import 'package:mony_time/src/shared/enums/transaction_type.dart';

/// A single money movement — the core entity of the app.
class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryEmoji,
    required this.categoryLabel,
    required this.source,
    required this.date,
    this.note = '',
    this.isAuto = false,
  });

  final String id;
  final TransactionType type;

  /// Always positive — the sign is derived from [type].
  final double amount;

  final String categoryEmoji;
  final String categoryLabel;

  /// Account / payment method: `Cash`, `Visa`, `Bank — Main` …
  final String source;

  final DateTime date;
  final String note;

  /// True when captured automatically via the iOS Shortcut link.
  final bool isAuto;

  bool get isIncome => type == TransactionType.income;

  /// Date normalised to midnight — used for day grouping and calendar lookups.
  DateTime get day => DateTime(date.year, date.month, date.day);

  Transaction copyWith({
    TransactionType? type,
    double? amount,
    String? categoryEmoji,
    String? categoryLabel,
    String? source,
    DateTime? date,
    String? note,
    bool? isAuto,
  }) {
    return Transaction(
      id: id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryEmoji: categoryEmoji ?? this.categoryEmoji,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      source: source ?? this.source,
      date: date ?? this.date,
      note: note ?? this.note,
      isAuto: isAuto ?? this.isAuto,
    );
  }

  @override
  List<Object?> get props =>
      [id, type, amount, categoryEmoji, categoryLabel, source, date, note, isAuto];
}

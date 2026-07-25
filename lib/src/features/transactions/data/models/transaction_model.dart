import 'package:mony_time/src/features/transactions/domain/entities/transaction.dart';
import 'package:mony_time/src/shared/enums/transaction_type.dart';

/// Data-layer representation of [Transaction] with JSON mapping.
class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.type,
    required super.amount,
    required super.categoryEmoji,
    required super.categoryLabel,
    required super.source,
    required super.date,
    super.note,
    super.isAuto,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final data = (json['transaction'] ?? json) as Map<String, dynamic>;
    return TransactionModel(
      id: data['id'].toString(),
      type: data['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      amount: (data['amount'] as num).toDouble(),
      categoryEmoji: (data['category_emoji'] ?? '') as String,
      categoryLabel: (data['category_label'] ?? '') as String,
      source: (data['source'] ?? '') as String,
      date: DateTime.parse(data['date'] as String),
      note: (data['note'] ?? '') as String,
      isAuto: (data['is_auto'] ?? false) as bool,
    );
  }

  factory TransactionModel.fromEntity(Transaction transaction) {
    return TransactionModel(
      id: transaction.id,
      type: transaction.type,
      amount: transaction.amount,
      categoryEmoji: transaction.categoryEmoji,
      categoryLabel: transaction.categoryLabel,
      source: transaction.source,
      date: transaction.date,
      note: transaction.note,
      isAuto: transaction.isAuto,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type == TransactionType.income ? 'income' : 'expense',
        'amount': amount,
        'category_emoji': categoryEmoji,
        'category_label': categoryLabel,
        'source': source,
        'date': date.toIso8601String(),
        'note': note,
        'is_auto': isAuto,
      };
}

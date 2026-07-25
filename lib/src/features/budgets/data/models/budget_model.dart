import 'package:mony_time/src/features/budgets/domain/entities/budget.dart';
import 'package:mony_time/src/shared/enums/transaction_type.dart';

/// Data-layer representation of [Budget] with JSON mapping.
class BudgetModel extends Budget {
  const BudgetModel({
    required super.categoryEmoji,
    required super.categoryLabel,
    required super.type,
    required super.limit,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    final data = (json['budget'] ?? json) as Map<String, dynamic>;
    return BudgetModel(
      categoryEmoji: (data['category_emoji'] ?? '') as String,
      categoryLabel: (data['category_label'] ?? '') as String,
      type: data['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      limit: ((data['limit'] ?? 0) as num).toDouble(),
    );
  }

  factory BudgetModel.fromEntity(Budget budget) => BudgetModel(
        categoryEmoji: budget.categoryEmoji,
        categoryLabel: budget.categoryLabel,
        type: budget.type,
        limit: budget.limit,
      );

  Map<String, dynamic> toJson() => {
        'category_emoji': categoryEmoji,
        'category_label': categoryLabel,
        'type': type == TransactionType.income ? 'income' : 'expense',
        'limit': limit,
      };
}

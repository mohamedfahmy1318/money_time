import 'package:equatable/equatable.dart';

import 'package:mony_time/src/shared/enums/transaction_type.dart';

/// How far a budget is consumed.
enum BudgetStatus { onTrack, warning, over }

/// A monthly limit for one category (income target or expense cap).
class Budget extends Equatable {
  const Budget({
    required this.categoryEmoji,
    required this.categoryLabel,
    required this.type,
    required this.limit,
  });

  final String categoryEmoji;
  final String categoryLabel;
  final TransactionType type;

  /// Monthly limit; 0 = not set.
  final double limit;

  bool get isSet => limit > 0;

  Budget copyWith({double? limit}) => Budget(
        categoryEmoji: categoryEmoji,
        categoryLabel: categoryLabel,
        type: type,
        limit: limit ?? this.limit,
      );

  /// Consumption bucket for [spent] against this limit.
  BudgetStatus statusFor(double spent) {
    if (!isSet) return BudgetStatus.onTrack;
    final fraction = spent / limit;
    if (fraction > 1) return BudgetStatus.over;
    if (fraction >= 0.75) return BudgetStatus.warning;
    return BudgetStatus.onTrack;
  }

  @override
  List<Object?> get props => [categoryEmoji, categoryLabel, type, limit];
}

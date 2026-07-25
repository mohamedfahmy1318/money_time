import 'package:equatable/equatable.dart';

import 'package:mony_time/src/features/transactions/domain/entities/transaction.dart';
import 'package:mony_time/src/shared/enums/transaction_type.dart';

/// The filter the ledger applies to its lists, produced by the filter screen.
class TransactionFilter extends Equatable {
  const TransactionFilter({this.type, this.categories});

  /// Restrict to income or expense; `null` = both.
  final TransactionType? type;

  /// Category labels to keep; `null` = all categories.
  final Set<String>? categories;

  bool get isActive => type != null || categories != null;

  bool matches(Transaction t) =>
      (type == null || t.type == type) &&
      (categories == null || categories!.contains(t.categoryLabel));

  List<Transaction> apply(List<Transaction> list) =>
      list.where(matches).toList();

  @override
  List<Object?> get props => [type, categories];
}

/// Route arguments for the filter screen: the month being filtered and the
/// filter currently in effect.
class FilterScreenArgs {
  const FilterScreenArgs({required this.month, this.current});

  final DateTime month;
  final TransactionFilter? current;
}

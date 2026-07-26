import 'package:mony_time/src/imports/core_imports.dart';

import 'package:mony_time/src/features/transactions/domain/entities/transaction.dart';

/// Placeholder recurring rules for the UI phase, modelled as [Transaction]s so
/// they render through the shared [TransactionRow]. The [Transaction.source]
/// carries the schedule text (shown as the row subtitle). Names are plain
/// strings — they become user data once recurring rules reach the backend.
abstract final class RecurringSampleData {
  static final _date = DateTime(2026, 1, 1);

  static final items = <Transaction>[
    Transaction(
      id: 'r1',
      type: TransactionType.income,
      amount: 6000,
      categoryEmoji: '💰',
      categoryLabel: 'Salary',
      source: 'Monthly · day 25',
      date: _date,
    ),
    Transaction(
      id: 'r2',
      type: TransactionType.expense,
      amount: 3500,
      categoryEmoji: '🏠',
      categoryLabel: 'Rent',
      source: 'Monthly · day 1',
      date: _date,
    ),
    Transaction(
      id: 'r3',
      type: TransactionType.expense,
      amount: 165,
      categoryEmoji: '🎬',
      categoryLabel: 'Netflix',
      source: 'Monthly · day 15',
      date: _date,
    ),
    Transaction(
      id: 'r4',
      type: TransactionType.expense,
      amount: 450,
      categoryEmoji: '🏋️',
      categoryLabel: 'Gym',
      source: 'Monthly · day 5',
      date: _date,
    ),
  ];
}

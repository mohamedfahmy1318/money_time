import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/transactions/domain/entities/transaction.dart';

/// Contract implemented by the data layer.
///
/// Presentation never talks to this directly — it goes through the use cases.
abstract class TransactionsRepository {
  /// All transactions, newest first.
  FutureEither<List<Transaction>> getTransactions();

  /// Persist a new transaction; returns it as stored.
  FutureEither<Transaction> addTransaction(Transaction transaction);

  /// Update an existing transaction; returns it as stored.
  FutureEither<Transaction> updateTransaction(Transaction transaction);

  /// Remove a transaction by id.
  FutureEither<void> deleteTransaction(String id);
}

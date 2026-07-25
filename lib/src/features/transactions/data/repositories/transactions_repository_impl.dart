import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/transactions/data/datasources/transactions_remote_data_source.dart';
import 'package:mony_time/src/features/transactions/data/models/transaction_model.dart';
import 'package:mony_time/src/features/transactions/domain/entities/transaction.dart';
import 'package:mony_time/src/features/transactions/domain/repositories/transactions_repository.dart';

/// Wraps the datasource with `runTask` so every call returns
/// `Either<Failure, T>` — no exceptions escape the data layer.
///
/// `requiresNetwork` stays off while the datasource is mock/in-memory; flip it
/// on together with the real API.
class TransactionsRepositoryImpl implements TransactionsRepository {
  TransactionsRepositoryImpl(this._remote);

  final TransactionsRemoteDataSource _remote;

  @override
  FutureEither<List<Transaction>> getTransactions() {
    return runTask(() => _remote.getTransactions());
  }

  @override
  FutureEither<Transaction> addTransaction(Transaction transaction) {
    return runTask(
      () => _remote.addTransaction(TransactionModel.fromEntity(transaction)),
    );
  }

  @override
  FutureEither<Transaction> updateTransaction(Transaction transaction) {
    return runTask(
      () => _remote.updateTransaction(TransactionModel.fromEntity(transaction)),
    );
  }

  @override
  FutureEither<void> deleteTransaction(String id) {
    return runTask(() => _remote.deleteTransaction(id));
  }
}

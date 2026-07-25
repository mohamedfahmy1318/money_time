import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/transactions/domain/entities/transaction.dart';
import 'package:mony_time/src/features/transactions/domain/repositories/transactions_repository.dart';

class UpdateTransactionUseCase {
  const UpdateTransactionUseCase(this._repository);

  final TransactionsRepository _repository;

  FutureEither<Transaction> call(Transaction transaction) =>
      _repository.updateTransaction(transaction);
}

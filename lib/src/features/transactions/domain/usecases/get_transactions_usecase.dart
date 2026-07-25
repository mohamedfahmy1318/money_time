import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/transactions/domain/entities/transaction.dart';
import 'package:mony_time/src/features/transactions/domain/repositories/transactions_repository.dart';

class GetTransactionsUseCase {
  const GetTransactionsUseCase(this._repository);

  final TransactionsRepository _repository;

  FutureEither<List<Transaction>> call() => _repository.getTransactions();
}

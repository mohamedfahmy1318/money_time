import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/transactions/domain/repositories/transactions_repository.dart';

class DeleteTransactionUseCase {
  const DeleteTransactionUseCase(this._repository);

  final TransactionsRepository _repository;

  FutureEither<void> call(String id) => _repository.deleteTransaction(id);
}

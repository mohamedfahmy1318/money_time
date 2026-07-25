import 'package:mony_time/src/features/transactions/data/datasources/transactions_remote_data_source.dart';
import 'package:mony_time/src/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:mony_time/src/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:mony_time/src/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:mony_time/src/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:mony_time/src/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:mony_time/src/features/transactions/domain/usecases/update_transaction_usecase.dart';
import 'package:mony_time/src/features/transactions/presentation/cubits/transactions_cubit.dart';

/// Simple manual wiring for the transactions feature — no DI framework needed.
abstract final class TransactionsDi {
  static final TransactionsRepository _repository =
      TransactionsRepositoryImpl(TransactionsRemoteDataSource());

  static TransactionsCubit transactionsCubit() => TransactionsCubit(
        getTransactions: GetTransactionsUseCase(_repository),
        addTransaction: AddTransactionUseCase(_repository),
        updateTransaction: UpdateTransactionUseCase(_repository),
        deleteTransaction: DeleteTransactionUseCase(_repository),
      );
}

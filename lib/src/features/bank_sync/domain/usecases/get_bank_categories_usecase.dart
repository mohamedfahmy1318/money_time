import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_sync_results.dart';
import 'package:mony_time/src/features/bank_sync/domain/repositories/bank_sync_repository.dart';
import 'package:mony_time/src/shared/enums/transaction_type.dart';

class GetBankCategoriesUseCase {
  const GetBankCategoriesUseCase(this._repository);

  final BankSyncRepository _repository;

  FutureEither<List<BankCategory>> call(TransactionType type) =>
      _repository.getCategories(type);
}

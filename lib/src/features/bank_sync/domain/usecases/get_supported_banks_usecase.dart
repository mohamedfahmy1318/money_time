import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank.dart';
import 'package:mony_time/src/features/bank_sync/domain/repositories/bank_sync_repository.dart';

class GetSupportedBanksUseCase {
  const GetSupportedBanksUseCase(this._repository);

  final BankSyncRepository _repository;

  FutureEither<List<Bank>> call() => _repository.getSupportedBanks();
}

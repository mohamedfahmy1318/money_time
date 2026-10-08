import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_sync_summary.dart';
import 'package:mony_time/src/features/bank_sync/domain/repositories/bank_sync_repository.dart';

class GetBankSummaryUseCase {
  const GetBankSummaryUseCase(this._repository);

  final BankSyncRepository _repository;

  FutureEither<BankSyncSummary> call() => _repository.getSummary();
}

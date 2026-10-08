import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_sync_results.dart';
import 'package:mony_time/src/features/bank_sync/domain/repositories/bank_sync_repository.dart';

class ImportBankMessagesUseCase {
  const ImportBankMessagesUseCase(this._repository);

  final BankSyncRepository _repository;

  FutureEither<BulkImportResult> call(List<String> ids) =>
      _repository.importMessages(ids);
}

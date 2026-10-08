import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_sync_results.dart';
import 'package:mony_time/src/features/bank_sync/domain/repositories/bank_sync_repository.dart';

class ImportBankMessageUseCase {
  const ImportBankMessageUseCase(this._repository);

  final BankSyncRepository _repository;

  FutureEither<BankImportResult> call(
    String id, {
    ImportOverrides overrides = ImportOverrides.none,
  }) {
    return _repository.importMessage(id, overrides);
  }
}

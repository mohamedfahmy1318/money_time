import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_sync_results.dart';
import 'package:mony_time/src/features/bank_sync/domain/repositories/bank_sync_repository.dart';

/// The wizard's "Import the last 30 days": runs after connect, uploads bank
/// SMS already on the device. Everything it finds waits for review.
class ImportRecentSmsUseCase {
  const ImportRecentSmsUseCase(this._repository);

  final BankSyncRepository _repository;

  FutureEither<HistoryScanResult> call({required List<String> bankIds}) =>
      _repository.importRecentHistory(bankIds: bankIds);
}

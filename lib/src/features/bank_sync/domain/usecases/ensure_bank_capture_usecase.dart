import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_link.dart';
import 'package:mony_time/src/features/bank_sync/domain/repositories/bank_sync_repository.dart';

class EnsureBankCaptureUseCase {
  const EnsureBankCaptureUseCase(this._repository);

  final BankSyncRepository _repository;

  FutureEither<CaptureReport> call(BankLink link) =>
      _repository.ensureCapture(link);
}

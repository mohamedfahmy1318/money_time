import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/bank_sync/domain/repositories/bank_sync_repository.dart';

class DisconnectBankLinkUseCase {
  const DisconnectBankLinkUseCase(this._repository);

  final BankSyncRepository _repository;

  FutureEither<void> call() => _repository.disconnect();
}

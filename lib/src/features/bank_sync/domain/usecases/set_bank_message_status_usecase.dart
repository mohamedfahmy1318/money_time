import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/domain/repositories/bank_sync_repository.dart';

class SetBankMessageStatusUseCase {
  const SetBankMessageStatusUseCase(this._repository);

  final BankSyncRepository _repository;

  FutureEither<List<BankMessage>> call(
    List<String> ids,
    BankMessageStatus status,
  ) {
    return _repository.setStatus(ids, status);
  }
}

import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/domain/repositories/bank_sync_repository.dart';

class GetBankMessagesUseCase {
  const GetBankMessagesUseCase(this._repository);

  final BankSyncRepository _repository;

  FutureEither<List<BankMessage>> call() => _repository.getMessages();
}

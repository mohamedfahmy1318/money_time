import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_sync_results.dart';
import 'package:mony_time/src/features/bank_sync/domain/repositories/bank_sync_repository.dart';

class GetBankMessagesUseCase {
  const GetBankMessagesUseCase(this._repository);

  final BankSyncRepository _repository;

  FutureEither<BankMessagePage> call({
    required BankMessageStatus status,
    String? cursor,
    int limit = 100,
  }) {
    return _repository.getMessages(
        status: status, cursor: cursor, limit: limit);
  }
}

import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_sync_results.dart';
import 'package:mony_time/src/features/bank_sync/domain/repositories/bank_sync_repository.dart';

/// Stores an SMS the user pasted; the server parses it (the on-device parser
/// only drives the sheet's live preview).
class SubmitBankMessageUseCase {
  const SubmitBankMessageUseCase(this._repository);

  final BankSyncRepository _repository;

  FutureEither<SubmittedBankMessage> call({
    required String sender,
    required String body,
  }) {
    return _repository.submitMessage(sender: sender, body: body);
  }
}

import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/domain/parsing/bank_sms_parser.dart';
import 'package:mony_time/src/features/bank_sync/domain/repositories/bank_sync_repository.dart';

/// Parses an incoming bank SMS on-device and stores it. Messages that are not
/// transactions (OTP, promos) are kept but filed straight under ignored, so
/// the review queue only ever holds real money movements.
class IngestBankMessageUseCase {
  const IngestBankMessageUseCase(this._repository);

  final BankSyncRepository _repository;

  FutureEither<BankMessage> call({
    required String sender,
    required String body,
    DateTime? receivedAt,
  }) {
    final at = receivedAt ?? DateTime.now();
    final parsed = BankSmsParser.parse(body, receivedAt: at);
    return _repository.saveMessage(
      sender: sender,
      body: body,
      receivedAt: at,
      parsed: parsed,
      status:
          parsed == null ? BankMessageStatus.ignored : BankMessageStatus.pending,
    );
  }
}

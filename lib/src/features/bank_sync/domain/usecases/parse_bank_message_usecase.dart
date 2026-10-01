import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/domain/parsing/bank_sms_parser.dart';

/// Reads a raw SMS without storing it — drives the live preview while the user
/// pastes a message. Synchronous and pure, so it has no failure path.
class ParseBankMessageUseCase {
  const ParseBankMessageUseCase();

  ParsedBankSms? call(String body, {DateTime? receivedAt}) =>
      BankSmsParser.parse(body, receivedAt: receivedAt);
}

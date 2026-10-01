import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_link.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';

/// Contract implemented by the data layer.
abstract class BankSyncRepository {
  /// Banks whose alerts can be read.
  FutureEither<List<Bank>> getSupportedBanks();

  /// The current connection (disconnected by default).
  FutureEither<BankLink> getLink();

  /// Starts reading alerts from [bankIds]; returns the live link.
  FutureEither<BankLink> connect({
    required BankLinkMethod method,
    required List<String> bankIds,
    required ImportMode mode,
  });

  /// Persists changed banks / import mode.
  FutureEither<BankLink> updateLink(BankLink link);

  /// Stops reading alerts. Already-received messages are kept.
  FutureEither<void> disconnect();

  /// Every received message, newest first.
  FutureEither<List<BankMessage>> getMessages();

  /// Stores a newly received message (already parsed on-device).
  FutureEither<BankMessage> saveMessage({
    required String sender,
    required String body,
    required DateTime receivedAt,
    required BankMessageStatus status,
    ParsedBankSms? parsed,
  });

  /// Moves messages to [status]; returns the updated messages.
  FutureEither<List<BankMessage>> setMessageStatus(
    List<String> ids,
    BankMessageStatus status,
  );
}

import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/bank_sync/data/datasources/bank_sync_remote_data_source.dart';
import 'package:mony_time/src/features/bank_sync/data/models/bank_link_model.dart';
import 'package:mony_time/src/features/bank_sync/data/models/bank_message_model.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_link.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/domain/repositories/bank_sync_repository.dart';

/// Wraps the datasource with `runTask` so every call returns
/// `Either<Failure, T>`. `requiresNetwork` stays off while mock.
class BankSyncRepositoryImpl implements BankSyncRepository {
  BankSyncRepositoryImpl(this._remote);

  final BankSyncRemoteDataSource _remote;

  @override
  FutureEither<List<Bank>> getSupportedBanks() {
    return runTask(() => _remote.getSupportedBanks());
  }

  @override
  FutureEither<BankLink> getLink() => runTask(() => _remote.getLink());

  @override
  FutureEither<BankLink> connect({
    required BankLinkMethod method,
    required List<String> bankIds,
    required ImportMode mode,
  }) {
    return runTask(
      () => _remote.connect(method: method, bankIds: bankIds, mode: mode),
    );
  }

  @override
  FutureEither<BankLink> updateLink(BankLink link) {
    return runTask(() => _remote.updateLink(BankLinkModel.fromEntity(link)));
  }

  @override
  FutureEither<void> disconnect() => runTask(() => _remote.disconnect());

  @override
  FutureEither<List<BankMessage>> getMessages() {
    return runTask(() => _remote.getMessages());
  }

  @override
  FutureEither<BankMessage> saveMessage({
    required String sender,
    required String body,
    required DateTime receivedAt,
    required BankMessageStatus status,
    ParsedBankSms? parsed,
  }) {
    return runTask(
      () => _remote.saveMessage(
        BankMessageModel(
          id: '',
          bankId: '',
          sender: sender,
          body: body,
          receivedAt: receivedAt,
          status: status,
          parsed: parsed,
        ),
      ),
    );
  }

  @override
  FutureEither<List<BankMessage>> setMessageStatus(
    List<String> ids,
    BankMessageStatus status,
  ) {
    return runTask(() => _remote.setMessageStatus(ids, status));
  }
}

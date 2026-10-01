import 'package:mony_time/src/features/bank_sync/data/datasources/bank_sync_remote_data_source.dart';
import 'package:mony_time/src/features/bank_sync/data/repositories/bank_sync_repository_impl.dart';
import 'package:mony_time/src/features/bank_sync/domain/repositories/bank_sync_repository.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/connect_bank_link_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/disconnect_bank_link_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/get_bank_link_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/get_bank_messages_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/get_supported_banks_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/ingest_bank_message_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/parse_bank_message_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/set_bank_message_status_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/update_bank_link_usecase.dart';
import 'package:mony_time/src/features/bank_sync/presentation/cubits/bank_sync_cubit.dart';

/// Simple manual wiring for the bank-SMS feature — no DI framework needed.
abstract final class BankSyncDi {
  static final BankSyncRepository _repository =
      BankSyncRepositoryImpl(BankSyncRemoteDataSource());

  static BankSyncCubit bankSyncCubit() => BankSyncCubit(
        getBanks: GetSupportedBanksUseCase(_repository),
        getLink: GetBankLinkUseCase(_repository),
        connect: ConnectBankLinkUseCase(_repository),
        updateLink: UpdateBankLinkUseCase(_repository),
        disconnect: DisconnectBankLinkUseCase(_repository),
        getMessages: GetBankMessagesUseCase(_repository),
        ingest: IngestBankMessageUseCase(_repository),
        setStatus: SetBankMessageStatusUseCase(_repository),
      );

  /// Stateless parser for the paste sheet's live preview.
  static const ParseBankMessageUseCase parseMessage = ParseBankMessageUseCase();
}

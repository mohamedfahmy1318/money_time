import 'package:flutter/foundation.dart';

import 'package:mony_time/src/features/bank_sync/data/datasources/bank_capture_local_data_source.dart';
import 'package:mony_time/src/features/bank_sync/data/datasources/bank_sync_remote_data_source.dart';
import 'package:mony_time/src/features/bank_sync/data/repositories/bank_sync_repository_impl.dart';
import 'package:mony_time/src/features/bank_sync/domain/repositories/bank_sync_repository.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/connect_bank_link_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/disconnect_bank_link_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/ensure_bank_capture_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/get_bank_categories_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/get_bank_link_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/get_bank_messages_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/get_bank_summary_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/get_supported_banks_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/import_bank_message_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/import_bank_messages_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/import_recent_sms_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/parse_bank_message_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/reissue_bank_capture_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/set_bank_message_status_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/stop_bank_capture_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/submit_bank_message_usecase.dart';
import 'package:mony_time/src/features/bank_sync/domain/usecases/update_bank_link_usecase.dart';
import 'package:mony_time/src/features/bank_sync/presentation/cubits/bank_sync_cubit.dart';

/// Simple manual wiring for the bank-SMS feature — no DI framework needed.
abstract final class BankSyncDi {
  static BankSyncRepository? _override;
  static BankSyncRepository? _repository;

  static BankSyncRepository get _repo =>
      _override ??
      (_repository ??= BankSyncRepositoryImpl(
        BankSyncRemoteDataSource(),
        BankCaptureLocalDataSource(),
      ));

  /// Tests swap the live repository for a fake.
  @visibleForTesting
  static set repository(BankSyncRepository repository) =>
      _override = repository;

  static BankSyncCubit bankSyncCubit() {
    final repo = _repo;
    return BankSyncCubit(
      getBanks: GetSupportedBanksUseCase(repo),
      getLink: GetBankLinkUseCase(repo),
      connect: ConnectBankLinkUseCase(repo),
      updateLink: UpdateBankLinkUseCase(repo),
      disconnect: DisconnectBankLinkUseCase(repo),
      getSummary: GetBankSummaryUseCase(repo),
      getMessages: GetBankMessagesUseCase(repo),
      submit: SubmitBankMessageUseCase(repo),
      setStatus: SetBankMessageStatusUseCase(repo),
      importOne: ImportBankMessageUseCase(repo),
      importMany: ImportBankMessagesUseCase(repo),
      getCategories: GetBankCategoriesUseCase(repo),
      importRecent: ImportRecentSmsUseCase(repo),
      ensureCapture: EnsureBankCaptureUseCase(repo),
      reissueCapture: ReissueBankCaptureUseCase(repo),
      stopCapture: StopBankCaptureUseCase(repo),
      hasSession: () => repo.hasSession,
      deviceMethod: repo.deviceMethod,
      capturedMessages: repo.capturedMessages,
    );
  }

  /// Stateless parser for the paste sheet's live preview.
  static const ParseBankMessageUseCase parseMessage = ParseBankMessageUseCase();
}

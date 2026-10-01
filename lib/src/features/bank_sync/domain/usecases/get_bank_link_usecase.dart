import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_link.dart';
import 'package:mony_time/src/features/bank_sync/domain/repositories/bank_sync_repository.dart';

class GetBankLinkUseCase {
  const GetBankLinkUseCase(this._repository);

  final BankSyncRepository _repository;

  FutureEither<BankLink> call() => _repository.getLink();
}

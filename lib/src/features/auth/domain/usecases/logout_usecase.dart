import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/auth/domain/repositories/auth_repository.dart';

class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  FutureEither<void> call() => _repository.logout();
}

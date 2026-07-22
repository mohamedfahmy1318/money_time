import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/auth/domain/entities/user.dart';
import 'package:mony_time/src/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  FutureEither<AppUser?> call() => _repository.getCurrentUser();
}

import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/auth/domain/entities/user.dart';
import 'package:mony_time/src/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  FutureEither<AppUser> call({
    required String email,
    required String password,
  }) {
    return _repository.login(email: email, password: password);
  }
}

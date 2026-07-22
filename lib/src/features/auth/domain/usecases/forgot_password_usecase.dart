import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/auth/domain/repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  const ForgotPasswordUseCase(this._repository);

  final AuthRepository _repository;

  FutureEither<void> call({required String email}) {
    return _repository.forgotPassword(email: email);
  }
}

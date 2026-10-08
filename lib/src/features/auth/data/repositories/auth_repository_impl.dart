import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mony_time/src/features/auth/domain/entities/user.dart';
import 'package:mony_time/src/features/auth/domain/repositories/auth_repository.dart';

/// Wraps the datasource with `runTask` so every call returns
/// `Either<Failure, T>` — no exceptions escape the data layer.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Stream<void> get sessionEnded => _remote.sessionEnded;

  @override
  FutureEither<AppUser> login({
    required String email,
    required String password,
  }) {
    return runTask(() => _remote.login(email: email, password: password));
  }

  @override
  FutureEither<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return runTask(
      () => _remote.signUp(name: name, email: email, password: password),
    );
  }

  @override
  FutureEither<void> forgotPassword({required String email}) {
    return runTask(() => _remote.forgotPassword(email: email));
  }

  @override
  FutureEither<void> logout() {
    return runTask(() => _remote.logout());
  }

  @override
  FutureEither<AppUser?> getCurrentUser() {
    return runTask(() => _remote.getCurrentUser());
  }
}

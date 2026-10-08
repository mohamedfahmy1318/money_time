import 'package:mony_time/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mony_time/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mony_time/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:mony_time/src/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:mony_time/src/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:mony_time/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:mony_time/src/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mony_time/src/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:mony_time/src/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:mony_time/src/features/auth/presentation/cubits/session_cubit.dart';

/// Simple manual wiring for the auth feature — no DI framework needed.
///
/// Every feature gets one `<feature>_di.dart` like this: it owns the
/// repository singleton and exposes factory methods for the cubits.
abstract final class AuthDi {
  static final AuthRepository _repository =
      AuthRepositoryImpl(AuthRemoteDataSource());

  static AuthCubit authCubit() => AuthCubit(
        login: LoginUseCase(_repository),
        signUp: SignUpUseCase(_repository),
        forgotPassword: ForgotPasswordUseCase(_repository),
      );

  static SessionCubit sessionCubit() => SessionCubit(
        getCurrentUser: GetCurrentUserUseCase(_repository),
        logout: LogoutUseCase(_repository),
        sessionEnded: _repository.sessionEnded,
      );
}

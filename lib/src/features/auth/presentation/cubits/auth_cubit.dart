import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mony_time/src/features/auth/domain/entities/user.dart';
import 'package:mony_time/src/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:mony_time/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:mony_time/src/features/auth/domain/usecases/sign_up_usecase.dart';

enum AuthStatus { initial, loading, authenticated, resetLinkSent, failure }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;

  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];
}

/// Screen-scoped cubit: provided per auth screen via `AuthDi.authCubit()`.
///
/// No navigation or toasts here — it only emits state. The screen reacts
/// through a `BlocListener`.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required LoginUseCase login,
    required SignUpUseCase signUp,
    required ForgotPasswordUseCase forgotPassword,
  })  : _login = login,
        _signUp = signUp,
        _forgotPassword = forgotPassword,
        super(const AuthState());

  final LoginUseCase _login;
  final SignUpUseCase _signUp;
  final ForgotPasswordUseCase _forgotPassword;

  Future<void> login({required String email, required String password}) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await _login(email: email, password: password);

    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: failure.message,
      )),
      (user) => emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      )),
    );
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await _signUp(name: name, email: email, password: password);

    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: failure.message,
      )),
      (user) => emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      )),
    );
  }

  Future<void> forgotPassword({required String email}) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await _forgotPassword(email: email);

    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(status: AuthStatus.resetLinkSent)),
    );
  }
}

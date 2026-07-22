import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mony_time/src/features/auth/domain/entities/user.dart';
import 'package:mony_time/src/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:mony_time/src/features/auth/domain/usecases/logout_usecase.dart';

enum SessionStatus { unknown, authenticated, unauthenticated }

class SessionState extends Equatable {
  const SessionState({
    this.status = SessionStatus.unknown,
    this.user,
  });

  final SessionStatus status;
  final AppUser? user;

  @override
  List<Object?> get props => [status, user];
}

/// App-wide cubit provided once in `StateWrapper`.
///
/// Resolves the session at startup (`SessionListenerWrapper` reacts by
/// removing the splash and redirecting) and handles logout.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit({
    required GetCurrentUserUseCase getCurrentUser,
    required LogoutUseCase logout,
  })  : _getCurrentUser = getCurrentUser,
        _logout = logout,
        super(const SessionState()) {
    checkSession();
  }

  final GetCurrentUserUseCase _getCurrentUser;
  final LogoutUseCase _logout;

  Future<void> checkSession() async {
    final result = await _getCurrentUser();

    result.fold(
      (_) => emit(const SessionState(status: SessionStatus.unauthenticated)),
      (user) => emit(
        user == null
            ? const SessionState(status: SessionStatus.unauthenticated)
            : SessionState(status: SessionStatus.authenticated, user: user),
      ),
    );
  }

  /// Called by [AuthCubit] flows indirectly: after a successful login the
  /// screen navigates and can push the user here to keep session in sync.
  void setUser(AppUser user) {
    emit(SessionState(status: SessionStatus.authenticated, user: user));
  }

  Future<void> logout() async {
    await _logout();
    emit(const SessionState(status: SessionStatus.unauthenticated));
  }
}

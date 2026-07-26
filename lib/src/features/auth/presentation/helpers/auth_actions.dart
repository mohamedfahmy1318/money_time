import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:mony_time/src/routing/app_routes.dart';
import 'package:mony_time/src/features/auth/presentation/cubits/session_cubit.dart';
import 'package:mony_time/src/features/auth/presentation/models/auth_gate.dart';

/// Auth-aware navigation for guest mode. A guest can browse freely; any action
/// that mutates or saves data is routed through [guardedPush].
extension AuthActions on BuildContext {
  bool get isAuthenticated =>
      read<SessionCubit>().state.status == SessionStatus.authenticated;

  /// Pushes [route] when signed in; otherwise sends a guest to login and
  /// resumes [route] after a successful sign-in.
  void guardedPush(String route, {Object? extra}) {
    if (isAuthenticated) {
      push(route, extra: extra);
    } else {
      push(
        AppRoutes.login,
        extra: AuthGate(returnRoute: route, returnExtra: extra),
      );
    }
  }

  /// Runs an in-place mutation ([action]) when signed in; otherwise sends a
  /// guest to login. In-place actions can't be replayed after sign-in, so the
  /// guest simply retries once authenticated.
  void guardedRun(VoidCallback action) {
    if (isAuthenticated) {
      action();
    } else {
      push(AppRoutes.login);
    }
  }
}

import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/auth/domain/entities/user.dart';

/// Contract implemented by the data layer.
///
/// Presentation never talks to this directly — it goes through the use cases.
abstract class AuthRepository {
  /// Fires when the server ends the session (refresh rejected, token
  /// revoked) so the app can drop to guest mode.
  Stream<void> get sessionEnded;

  /// Sign in with email and password.
  FutureEither<AppUser> login({
    required String email,
    required String password,
  });

  /// Create a new account.
  FutureEither<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Send a password reset email.
  FutureEither<void> forgotPassword({required String email});

  /// Sign out the current user.
  FutureEither<void> logout();

  /// Returns the current user, or `null` when not authenticated.
  FutureEither<AppUser?> getCurrentUser();
}

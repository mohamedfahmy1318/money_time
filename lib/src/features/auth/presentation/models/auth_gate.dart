/// Describes where to resume after a guest signs in from a protected action.
///
/// Passed as the `extra` on the login/signup routes; the auth screen navigates
/// to [returnRoute] (with [returnExtra]) once authentication succeeds.
class AuthGate {
  const AuthGate({required this.returnRoute, this.returnExtra});

  final String returnRoute;
  final Object? returnExtra;
}

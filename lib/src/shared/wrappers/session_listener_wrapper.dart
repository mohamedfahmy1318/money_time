import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/auth/presentation/cubits/session_cubit.dart';

/// Removes the native splash once the session resolves and drives the two
/// app-level transitions that sit *above* go_router's `InheritedGoRouter`
/// (so they navigate through the [appRouter] singleton, not `context.go`):
///
/// * the initial landing after the session settles — authenticated users go to
///   home, guests go to home too once first-run is done, otherwise to the
///   language step;
/// * logout — back to home in guest mode.
///
/// Sign-in is deliberately *not* handled here: the login/signup screens own
/// their own post-auth navigation (resuming the pending action or the welcome
/// funnel), and handling it here would clobber that.
class SessionListenerWrapper extends StatefulWidget {
  final Widget child;
  const SessionListenerWrapper({super.key, required this.child});

  @override
  State<SessionListenerWrapper> createState() => _SessionListenerWrapperState();
}

class _SessionListenerWrapperState extends State<SessionListenerWrapper> {
  bool _resolved = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionCubit, SessionState>(
      listenWhen: (prev, next) => prev.status != next.status,
      listener: (context, state) {
        if (state.status == SessionStatus.unknown) return;

        final authenticated = state.status == SessionStatus.authenticated;

        if (!_resolved) {
          _resolved = true;
          FlutterNativeSplash.remove();
          appRouter.go(
            authenticated || AppPrefs.onboardingCompleted
                ? AppRoutes.home
                : AppRoutes.language,
          );
          return;
        }

        // Post-startup: only logout needs steering (back to guest home).
        // Sign-in navigation is owned by the auth screens.
        if (!authenticated) appRouter.go(AppRoutes.home);
      },
      child: widget.child,
    );
  }
}

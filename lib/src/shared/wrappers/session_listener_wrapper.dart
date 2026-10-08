import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/auth/presentation/cubits/session_cubit.dart';
import 'package:mony_time/src/features/bank_sync/presentation/cubits/bank_sync_cubit.dart';

/// Removes the native splash once the session resolves and drives the two
/// app-level transitions that sit *above* go_router's `InheritedGoRouter`
/// (so they navigate through the [appRouter] singleton, not `context.go`):
///
/// * the initial landing after the session settles — authenticated users go to
///   home, guests go to home too once first-run is done, otherwise to the
///   language step;
/// * logout — back to home in guest mode.
///
/// It also keeps the bank-messages inbox on the session: loaded on sign-in,
/// and on sign-out cleared with this device's background SMS capture
/// disarmed.
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

  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back in the foreground: messages may have arrived meanwhile (an iPhone
    // Shortcut or the Android worker ran while the app was closed).
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (_resolved) context.read<BankSyncCubit>().refresh();
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionCubit, SessionState>(
      listenWhen: (prev, next) => prev.status != next.status,
      listener: (context, state) {
        if (state.status == SessionStatus.unknown) return;

        final authenticated = state.status == SessionStatus.authenticated;
        final bankSync = context.read<BankSyncCubit>();

        if (!_resolved || authenticated) {
          bankSync.load();
        } else {
          bankSync.signOut();
        }

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

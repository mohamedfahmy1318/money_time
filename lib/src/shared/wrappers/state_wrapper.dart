import '../../imports/imports.dart';
import '../../features/auth/auth_di.dart';
import '../../features/auth/presentation/cubits/session_cubit.dart';

/// Registers app-wide cubits. Feature-scoped cubits are provided per screen.
class StateWrapper extends StatelessWidget {
  final Widget child;

  const StateWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SessionCubit>(create: (_) => AuthDi.sessionCubit()),
      ],
      child: child,
    );
  }
}

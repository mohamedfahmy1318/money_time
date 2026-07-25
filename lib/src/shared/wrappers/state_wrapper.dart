import '../../imports/imports.dart';
import '../../features/auth/auth_di.dart';
import '../../features/auth/presentation/cubits/session_cubit.dart';
import '../../features/transactions/transactions_di.dart';
import '../../features/transactions/presentation/cubits/transactions_cubit.dart';
import '../../features/budgets/budgets_di.dart';
import '../../features/budgets/presentation/cubits/budgets_cubit.dart';

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
        BlocProvider<TransactionsCubit>(
          create: (_) => TransactionsDi.transactionsCubit(),
        ),
        BlocProvider<BudgetsCubit>(
          create: (_) => BudgetsDi.budgetsCubit(),
        ),
      ],
      child: child,
    );
  }
}

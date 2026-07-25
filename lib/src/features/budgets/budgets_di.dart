import 'package:mony_time/src/features/budgets/data/datasources/budgets_remote_data_source.dart';
import 'package:mony_time/src/features/budgets/data/repositories/budgets_repository_impl.dart';
import 'package:mony_time/src/features/budgets/domain/repositories/budgets_repository.dart';
import 'package:mony_time/src/features/budgets/domain/usecases/get_budgets_usecase.dart';
import 'package:mony_time/src/features/budgets/domain/usecases/set_budget_usecase.dart';
import 'package:mony_time/src/features/budgets/presentation/cubits/budgets_cubit.dart';

/// Simple manual wiring for the budgets feature — no DI framework needed.
abstract final class BudgetsDi {
  static final BudgetsRepository _repository =
      BudgetsRepositoryImpl(BudgetsRemoteDataSource());

  static BudgetsCubit budgetsCubit() => BudgetsCubit(
        getBudgets: GetBudgetsUseCase(_repository),
        setBudget: SetBudgetUseCase(_repository),
      );
}

import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/budgets/domain/entities/budget.dart';
import 'package:mony_time/src/features/budgets/domain/repositories/budgets_repository.dart';

class SetBudgetUseCase {
  const SetBudgetUseCase(this._repository);

  final BudgetsRepository _repository;

  FutureEither<Budget> call(Budget budget) => _repository.setBudget(budget);
}

import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/budgets/domain/entities/budget.dart';
import 'package:mony_time/src/features/budgets/domain/repositories/budgets_repository.dart';

class GetBudgetsUseCase {
  const GetBudgetsUseCase(this._repository);

  final BudgetsRepository _repository;

  FutureEither<List<Budget>> call() => _repository.getBudgets();
}

import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/budgets/domain/entities/budget.dart';

/// Contract implemented by the data layer.
abstract class BudgetsRepository {
  /// All category budgets (income targets + expense caps).
  FutureEither<List<Budget>> getBudgets();

  /// Persist a limit; returns the budget as stored.
  FutureEither<Budget> setBudget(Budget budget);
}

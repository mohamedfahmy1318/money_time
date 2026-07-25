import 'package:mony_time/src/utils/utils.dart';
import 'package:mony_time/src/features/budgets/data/datasources/budgets_remote_data_source.dart';
import 'package:mony_time/src/features/budgets/data/models/budget_model.dart';
import 'package:mony_time/src/features/budgets/domain/entities/budget.dart';
import 'package:mony_time/src/features/budgets/domain/repositories/budgets_repository.dart';

/// Wraps the datasource with `runTask` so every call returns
/// `Either<Failure, T>`. `requiresNetwork` stays off while mock.
class BudgetsRepositoryImpl implements BudgetsRepository {
  BudgetsRepositoryImpl(this._remote);

  final BudgetsRemoteDataSource _remote;

  @override
  FutureEither<List<Budget>> getBudgets() {
    return runTask(() => _remote.getBudgets());
  }

  @override
  FutureEither<Budget> setBudget(Budget budget) {
    return runTask(() => _remote.setBudget(BudgetModel.fromEntity(budget)));
  }
}

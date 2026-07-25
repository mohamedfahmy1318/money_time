import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mony_time/src/features/budgets/domain/entities/budget.dart';
import 'package:mony_time/src/features/budgets/domain/usecases/get_budgets_usecase.dart';
import 'package:mony_time/src/features/budgets/domain/usecases/set_budget_usecase.dart';
import 'package:mony_time/src/shared/enums/transaction_type.dart';

enum BudgetsStatus { initial, loading, ready, failure }

/// One-shot outcome of the latest save, listened to by the edit screen.
enum BudgetsAction { idle, saving, saveSuccess, failure }

class BudgetsState extends Equatable {
  const BudgetsState({
    this.status = BudgetsStatus.initial,
    this.budgets = const [],
    this.action = BudgetsAction.idle,
    this.errorMessage,
  });

  final BudgetsStatus status;
  final List<Budget> budgets;
  final BudgetsAction action;
  final String? errorMessage;

  bool get isLoading => status == BudgetsStatus.loading;
  bool get isSaving => action == BudgetsAction.saving;

  /// Budgets of one side (income targets / expense caps), seeded order.
  List<Budget> ofType(TransactionType type) =>
      budgets.where((b) => b.type == type).toList();

  /// Expense caps that are actually set — the rows on the Budget tab and the
  /// reports budget view.
  List<Budget> get activeExpense =>
      budgets.where((b) => b.type == TransactionType.expense && b.isSet).toList();

  BudgetsState copyWith({
    BudgetsStatus? status,
    List<Budget>? budgets,
    BudgetsAction? action,
    String? errorMessage,
  }) {
    return BudgetsState(
      status: status ?? this.status,
      budgets: budgets ?? this.budgets,
      action: action ?? this.action,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, budgets, action, errorMessage];
}

/// App-wide cubit owning the category budget limits — registered in
/// `StateWrapper` so the Budget tab, reports and settings share one source of
/// truth. Spend progress comes from combining these limits with
/// `TransactionsCubit` data in the widgets.
class BudgetsCubit extends Cubit<BudgetsState> {
  BudgetsCubit({
    required GetBudgetsUseCase getBudgets,
    required SetBudgetUseCase setBudget,
  })  : _getBudgets = getBudgets,
        _setBudget = setBudget,
        super(const BudgetsState()) {
    loadBudgets();
  }

  final GetBudgetsUseCase _getBudgets;
  final SetBudgetUseCase _setBudget;

  Future<void> loadBudgets() async {
    emit(state.copyWith(status: BudgetsStatus.loading));

    final result = await _getBudgets();

    result.fold(
      (failure) => emit(state.copyWith(
        status: BudgetsStatus.failure,
        errorMessage: failure.message,
      )),
      (budgets) => emit(state.copyWith(
        status: BudgetsStatus.ready,
        budgets: budgets,
      )),
    );
  }

  Future<void> setBudget(Budget budget) async {
    emit(state.copyWith(action: BudgetsAction.saving));

    final result = await _setBudget(budget);

    result.fold(
      (failure) => emit(state.copyWith(
        action: BudgetsAction.failure,
        errorMessage: failure.message,
      )),
      (stored) => emit(state.copyWith(
        action: BudgetsAction.saveSuccess,
        budgets: [
          for (final b in state.budgets)
            if (b.categoryLabel == stored.categoryLabel &&
                b.type == stored.type)
              stored
            else
              b,
        ],
      )),
    );
  }
}

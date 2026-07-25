import 'package:dio/dio.dart';

import 'package:mony_time/src/config/app_config.dart';
import 'package:mony_time/src/features/budgets/data/models/budget_model.dart';
import 'package:mony_time/src/shared/enums/transaction_type.dart';

/// Raw API calls for the budgets feature.
///
/// Throws on failure — error mapping happens in the repository via `runTask`.
/// While [AppConfig.useMockData] is `true` the class works against an
/// in-memory store seeded with the Figma reference limits.
class BudgetsRemoteDataSource {
  BudgetsRemoteDataSource({Dio? dio}) : _dio = dio ?? AppConfig.dio;

  final Dio _dio;

  static const _mockDelay = Duration(milliseconds: 250);

  Future<List<BudgetModel>> getBudgets() async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(_mockDelay);
      return List.of(_store);
    }
    final response = await _dio.get<List<dynamic>>('/budgets');
    return (response.data ?? const [])
        .map((e) => BudgetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BudgetModel> setBudget(BudgetModel budget) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(_mockDelay);
      final index = _store.indexWhere((b) =>
          b.categoryLabel == budget.categoryLabel && b.type == budget.type);
      if (index == -1) {
        _store.add(budget);
      } else {
        _store[index] = budget;
      }
      return budget;
    }
    final response = await _dio.put<Map<String, dynamic>>(
      '/budgets/${budget.categoryLabel}',
      data: budget.toJson(),
    );
    return BudgetModel.fromJson(response.data!);
  }

  // ── Mock store — the Figma reference limits ────────────────────────────────

  static final List<BudgetModel> _store = _seed();

  static List<BudgetModel> _seed() {
    const inc = TransactionType.income;
    const exp = TransactionType.expense;

    BudgetModel b(String emoji, String label, TransactionType type,
            double limit) =>
        BudgetModel(
            categoryEmoji: emoji,
            categoryLabel: label,
            type: type,
            limit: limit);

    return [
      // Income targets.
      b('🤑', 'Allowance', inc, 500),
      b('💰', 'Salary', inc, 6000),
      b('💵', 'Petty cash', inc, 0),
      b('🥇', 'Bonus', inc, 0),
      b('➕', 'Other', inc, 0),
      // Expense caps.
      b('🍜', 'Food', exp, 1200),
      b('🚕', 'Transport', exp, 800),
      b('🛍️', 'Shopping', exp, 500),
      b('🏠', 'Household', exp, 0),
      b('💊', 'Health', exp, 0),
      b('🎬', 'Culture', exp, 0),
      b('👕', 'Apparel', exp, 0),
    ];
  }
}

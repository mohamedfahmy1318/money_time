import 'package:dio/dio.dart';

import 'package:mony_time/src/config/app_config.dart';
import 'package:mony_time/src/features/transactions/data/models/transaction_model.dart';
import 'package:mony_time/src/shared/enums/transaction_type.dart';

/// Raw API calls for the transactions feature.
///
/// Throws on failure — error mapping happens in the repository via `runTask`.
///
/// While [AppConfig.useMockData] is `true` (no backend yet) the class works
/// against an in-memory store seeded relative to the current month, so the
/// whole flow — list, calendar, monthly totals, summary, search, CRUD — is
/// fully walkable. The real Dio calls sit right beside the mock branches.
class TransactionsRemoteDataSource {
  TransactionsRemoteDataSource({Dio? dio}) : _dio = dio ?? AppConfig.dio;

  final Dio _dio;

  static const _mockDelay = Duration(milliseconds: 250);

  Future<List<TransactionModel>> getTransactions() async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(_mockDelay);
      return List.of(_store);
    }
    final response = await _dio.get<List<dynamic>>('/transactions');
    return (response.data ?? const [])
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TransactionModel> addTransaction(TransactionModel transaction) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(_mockDelay);
      _store.add(transaction);
      return transaction;
    }
    final response = await _dio.post<Map<String, dynamic>>(
      '/transactions',
      data: transaction.toJson(),
    );
    return TransactionModel.fromJson(response.data!);
  }

  Future<TransactionModel> updateTransaction(
      TransactionModel transaction) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(_mockDelay);
      final index = _store.indexWhere((t) => t.id == transaction.id);
      if (index == -1) throw Exception('Transaction not found');
      _store[index] = transaction;
      return transaction;
    }
    final response = await _dio.put<Map<String, dynamic>>(
      '/transactions/${transaction.id}',
      data: transaction.toJson(),
    );
    return TransactionModel.fromJson(response.data!);
  }

  Future<void> deleteTransaction(String id) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(_mockDelay);
      _store.removeWhere((t) => t.id == id);
      return;
    }
    await _dio.delete<void>('/transactions/$id');
  }

  // ── Mock store ─────────────────────────────────────────────────────────────

  static final List<TransactionModel> _store = _seed();

  /// Seeds months relative to "now" so the ledger always has recent data.
  /// Month −2 reproduces the Figma reference month exactly
  /// (income 5,820 / expense 2,450 → budget 49% of 5,000).
  static List<TransactionModel> _seed() {
    final now = DateTime.now();
    var id = 0;

    DateTime on(int monthsAgo, int day) =>
        DateTime(now.year, now.month - monthsAgo, day);

    TransactionModel txn(
      int monthsAgo,
      int day,
      TransactionType type,
      double amount,
      String emoji,
      String label,
      String source, {
      String note = '',
      bool isAuto = false,
    }) {
      return TransactionModel(
        id: 'seed-${++id}',
        type: type,
        amount: amount,
        categoryEmoji: emoji,
        categoryLabel: label,
        source: source,
        date: on(monthsAgo, day),
        note: note,
        isAuto: isAuto,
      );
    }

    const inc = TransactionType.income;
    const exp = TransactionType.expense;

    return [
      // Current month — totals 6,100 / 2,900.
      txn(0, 24, exp, 4.50, '☕', 'Coffee', 'Cash'),
      txn(0, 24, exp, 18, '🚕', 'Transport', 'Cash'),
      txn(0, 23, inc, 3200, '💰', 'Salary', 'Bank — Main'),
      txn(0, 23, exp, 145.50, '🛒', 'Groceries', 'Visa',
          note: 'Weekly shop', isAuto: true),
      txn(0, 15, exp, 1000, '🛍️', 'Shopping', 'Visa'),
      txn(0, 12, inc, 2900, '💼', 'Freelance', 'Bank — Main'),
      txn(0, 10, exp, 232, '💡', 'Electricity', 'Bank — Main',
          note: 'Monthly bill'),
      txn(0, 5, exp, 1500, '🏠', 'Rent', 'Bank — Main'),
      // Last month — totals 5,400 / 2,100.
      txn(1, 23, inc, 3200, '💰', 'Salary', 'Bank — Main'),
      txn(1, 18, exp, 380, '🛍️', 'Shopping', 'Visa'),
      txn(1, 14, inc, 2200, '💼', 'Freelance', 'Bank — Main'),
      txn(1, 9, exp, 220, '🛒', 'Groceries', 'Visa'),
      txn(1, 5, exp, 1500, '🏠', 'Rent', 'Bank — Main'),
      // Two months back — the Figma reference month: 5,820 / 2,450.
      txn(2, 23, inc, 3200, '💰', 'Salary', 'Bank — Main'),
      txn(2, 23, exp, 120.50, '🛒', 'Groceries', 'Visa',
          note: 'Weekly shop', isAuto: true),
      txn(2, 22, exp, 4.50, '☕', 'Coffee', 'Cash'),
      txn(2, 22, exp, 18, '🚕', 'Transport', 'Cash'),
      txn(2, 20, exp, 210, '💡', 'Electricity', 'Bank — Main',
          note: 'Monthly bill'),
      txn(2, 18, exp, 22, '☕', 'Coffee', 'Cash', note: 'Morning coffee'),
      txn(2, 15, inc, 2620, '💼', 'Freelance', 'Bank — Main'),
      txn(2, 11, exp, 20, '☕', 'Coffee', 'Visa', note: 'Coffee shop'),
      txn(2, 8, exp, 555, '🛍️', 'Shopping', 'Visa'),
      txn(2, 5, exp, 1500, '🏠', 'Rent', 'Bank — Main'),
      // Three months back — 4,900 / 3,050.
      txn(3, 23, inc, 3200, '💰', 'Salary', 'Bank — Main'),
      txn(3, 16, exp, 800, '🛍️', 'Shopping', 'Visa'),
      txn(3, 12, inc, 1700, '💼', 'Freelance', 'Bank — Main'),
      txn(3, 9, exp, 750, '🛒', 'Groceries', 'Visa'),
      txn(3, 5, exp, 1500, '🏠', 'Rent', 'Bank — Main'),
      // Four months back — 5,100 / 2,700.
      txn(4, 23, inc, 3200, '💰', 'Salary', 'Bank — Main'),
      txn(4, 17, exp, 700, '💊', 'Health', 'Cash'),
      txn(4, 12, inc, 1900, '💼', 'Freelance', 'Bank — Main'),
      txn(4, 8, exp, 500, '🛒', 'Groceries', 'Visa'),
      txn(4, 5, exp, 1500, '🏠', 'Rent', 'Bank — Main'),
      // Five and six months back — light months.
      txn(5, 23, inc, 3200, '💰', 'Salary', 'Bank — Main'),
      txn(5, 5, exp, 1500, '🏠', 'Rent', 'Bank — Main'),
      txn(6, 23, inc, 3200, '💰', 'Salary', 'Bank — Main'),
      txn(6, 5, exp, 1500, '🏠', 'Rent', 'Bank — Main'),
      // Seven months back — exercises the year stepper on the Monthly view.
      txn(7, 23, inc, 3200, '💰', 'Salary', 'Bank — Main'),
      txn(7, 20, exp, 250, '🎁', 'Gift', 'Cash'),
    ];
  }
}

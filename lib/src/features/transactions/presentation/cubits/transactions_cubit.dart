import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mony_time/src/utils/failure.dart';
import 'package:mony_time/src/features/transactions/domain/entities/transaction.dart';
import 'package:mony_time/src/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:mony_time/src/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:mony_time/src/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:mony_time/src/features/transactions/domain/usecases/update_transaction_usecase.dart';
import 'package:mony_time/src/shared/enums/transaction_type.dart';

/// Loading state of the transaction list itself.
enum TransactionsStatus { initial, loading, ready, failure }

/// One-shot outcome of the latest add / update / delete, listened to by the
/// screen that triggered it.
enum TransactionsAction { idle, saving, saveSuccess, deleteSuccess, failure }

class TransactionsState extends Equatable {
  const TransactionsState({
    this.status = TransactionsStatus.initial,
    this.transactions = const [],
    this.action = TransactionsAction.idle,
    this.errorMessage,
  });

  final TransactionsStatus status;

  /// All transactions, newest first.
  final List<Transaction> transactions;

  final TransactionsAction action;
  final String? errorMessage;

  bool get isLoading => status == TransactionsStatus.loading;
  bool get isSaving => action == TransactionsAction.saving;

  // ── Derived queries (pure — every view reads through these) ──────────────

  Transaction? byId(String id) {
    for (final t in transactions) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Transactions inside the given month, newest first.
  List<Transaction> monthOf(DateTime month) => transactions
      .where((t) => t.date.year == month.year && t.date.month == month.month)
      .toList();

  /// Transactions on the given day, newest first.
  List<Transaction> dayOf(DateTime day) =>
      transactions.where((t) => t.day == DateTime(day.year, day.month, day.day)).toList();

  /// The n most recent transactions (home "Recent").
  List<Transaction> latest(int n) => transactions.take(n).toList();

  /// Months of [year] that contain transactions, most recent first.
  List<DateTime> monthsWith(int year) {
    final months = <int>{};
    for (final t in transactions) {
      if (t.date.year == year) months.add(t.date.month);
    }
    final sorted = months.toList()..sort((a, b) => b.compareTo(a));
    return [for (final m in sorted) DateTime(year, m)];
  }

  /// Case-insensitive match on category, note and source, optionally scoped
  /// to a type.
  List<Transaction> search(String query, {TransactionType? type}) {
    final q = query.trim().toLowerCase();
    return transactions.where((t) {
      if (type != null && t.type != type) return false;
      if (q.isEmpty) return false;
      return t.categoryLabel.toLowerCase().contains(q) ||
          t.note.toLowerCase().contains(q) ||
          t.source.toLowerCase().contains(q);
    }).toList();
  }

  // ── List aggregates ────────────────────────────────────────────────────────

  static double sumIncome(List<Transaction> list) => list
      .where((t) => t.isIncome)
      .fold(0, (total, t) => total + t.amount);

  static double sumExpense(List<Transaction> list) => list
      .where((t) => !t.isIncome)
      .fold(0, (total, t) => total + t.amount);

  /// Groups a (newest-first) list into day → transactions, preserving order.
  static Map<DateTime, List<Transaction>> groupByDay(List<Transaction> list) {
    final groups = <DateTime, List<Transaction>>{};
    for (final t in list) {
      groups.putIfAbsent(t.day, () => []).add(t);
    }
    return groups;
  }

  TransactionsState copyWith({
    TransactionsStatus? status,
    List<Transaction>? transactions,
    TransactionsAction? action,
    String? errorMessage,
  }) {
    return TransactionsState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      action: action ?? this.action,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, transactions, action, errorMessage];
}

/// App-wide cubit owning the transaction list — registered in `StateWrapper`
/// so home, the ledger, search and the add/edit flow all share one source of
/// truth.
///
/// No navigation or toasts here — it only emits state. Screens react through
/// `BlocListener`s.
class TransactionsCubit extends Cubit<TransactionsState> {
  TransactionsCubit({
    required GetTransactionsUseCase getTransactions,
    required AddTransactionUseCase addTransaction,
    required UpdateTransactionUseCase updateTransaction,
    required DeleteTransactionUseCase deleteTransaction,
  })  : _getTransactions = getTransactions,
        _addTransaction = addTransaction,
        _updateTransaction = updateTransaction,
        _deleteTransaction = deleteTransaction,
        super(const TransactionsState()) {
    loadTransactions();
  }

  final GetTransactionsUseCase _getTransactions;
  final AddTransactionUseCase _addTransaction;
  final UpdateTransactionUseCase _updateTransaction;
  final DeleteTransactionUseCase _deleteTransaction;

  Future<void> loadTransactions() async {
    emit(state.copyWith(status: TransactionsStatus.loading));

    final result = await _getTransactions();

    result.fold(
      (failure) => emit(state.copyWith(
        status: TransactionsStatus.failure,
        errorMessage: failure.message,
      )),
      (transactions) => emit(state.copyWith(
        status: TransactionsStatus.ready,
        transactions: _sorted(transactions),
      )),
    );
  }

  Future<void> addTransaction(Transaction transaction) async {
    emit(state.copyWith(action: TransactionsAction.saving));

    final result = await _addTransaction(transaction);

    result.fold(
      _emitActionFailure,
      (stored) => emit(state.copyWith(
        action: TransactionsAction.saveSuccess,
        transactions: _sorted([...state.transactions, stored]),
      )),
    );
  }

  /// Adds several transactions as one action (bank-message import). Stops at
  /// the first failure; whatever was stored before it stays in the list.
  Future<void> addTransactions(List<Transaction> transactions) async {
    emit(state.copyWith(action: TransactionsAction.saving));

    final stored = <Transaction>[];
    for (final transaction in transactions) {
      final result = await _addTransaction(transaction);
      final failure = result.fold<Failure?>((f) => f, (t) {
        stored.add(t);
        return null;
      });
      if (failure != null) {
        emit(state.copyWith(
          action: TransactionsAction.failure,
          errorMessage: failure.message,
          transactions: _sorted([...state.transactions, ...stored]),
        ));
        return;
      }
    }

    emit(state.copyWith(
      action: TransactionsAction.saveSuccess,
      transactions: _sorted([...state.transactions, ...stored]),
    ));
  }

  Future<void> updateTransaction(Transaction transaction) async {
    emit(state.copyWith(action: TransactionsAction.saving));

    final result = await _updateTransaction(transaction);

    result.fold(
      _emitActionFailure,
      (stored) => emit(state.copyWith(
        action: TransactionsAction.saveSuccess,
        transactions: _sorted([
          for (final t in state.transactions)
            if (t.id == stored.id) stored else t,
        ]),
      )),
    );
  }

  Future<void> deleteTransaction(String id) async {
    emit(state.copyWith(action: TransactionsAction.saving));

    final result = await _deleteTransaction(id);

    result.fold(
      _emitActionFailure,
      (_) => emit(state.copyWith(
        action: TransactionsAction.deleteSuccess,
        transactions:
            state.transactions.where((t) => t.id != id).toList(),
      )),
    );
  }

  void _emitActionFailure(Failure failure) => emit(state.copyWith(
        action: TransactionsAction.failure,
        errorMessage: failure.message,
      ));

  static List<Transaction> _sorted(List<Transaction> list) {
    final copy = List.of(list)
      ..sort((a, b) => b.date.compareTo(a.date));
    return copy;
  }
}

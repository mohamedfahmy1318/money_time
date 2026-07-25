import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/categories/presentation/models/category.dart';
import 'package:mony_time/src/features/transactions/domain/entities/transaction.dart';
import 'package:mony_time/src/features/transactions/presentation/cubits/transactions_cubit.dart';
import 'package:mony_time/src/features/transactions/presentation/models/keypad_key.dart';
import 'package:mony_time/src/features/transactions/presentation/sections/amount_keypad.dart';
import 'package:mony_time/src/features/transactions/presentation/sections/transaction_details.dart';
import 'package:mony_time/src/features/transactions/presentation/widgets/note_sheet.dart';

/// Add — or, when [initial] is given, edit — a transaction: pick a type,
/// enter the amount on the keypad, choose date/category, optionally attach a
/// note. OK persists through the app-wide [TransactionsCubit].
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, this.initial});

  /// Transaction being edited; null means a new one.
  final Transaction? initial;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late TransactionType _type =
      widget.initial?.type ?? TransactionType.expense;
  late String _amount = _initialAmount;
  late String _note = widget.initial?.note ?? '';
  late String _categoryEmoji = widget.initial?.categoryEmoji ?? '🛒';
  late String _categoryLabel = widget.initial?.categoryLabel ?? 'Groceries';
  late DateTime _date = widget.initial?.date ?? DateTime.now();

  /// True until the user first touches the keypad, so the seeded amount is
  /// replaced by the first digit rather than appended to.
  bool _amountPristine = true;

  /// True after this screen fired the save — guards the shared cubit's action
  /// stream against events triggered elsewhere.
  bool _submitted = false;

  bool get _isEdit => widget.initial != null;

  String get _initialAmount {
    final amount = widget.initial?.amount;
    if (amount == null) return '0';
    return amount % 1 == 0
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
  }

  void _onKey(KeypadKey key) {
    switch (key.kind) {
      case KeypadKeyKind.digit:
        _appendToAmount(key.label);
      case KeypadKeyKind.operator:
      case KeypadKeyKind.equals:
        break; // Decorative until the calculator is implemented.
      case KeypadKeyKind.ok:
        _save();
    }
  }

  void _appendToAmount(String glyph) {
    setState(() {
      if (_amountPristine) {
        _amount = '';
        _amountPristine = false;
      }
      if (glyph == '.' && _amount.contains('.')) return;
      if (glyph == '.' && _amount.isEmpty) {
        _amount = '0.';
        return;
      }
      _amount += glyph;
    });
  }

  Future<void> _addNote() async {
    final result = await showNoteSheet(context, initial: _note);
    if (result != null) setState(() => _note = result);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickCategory() async {
    final result = await context.push<AppCategory>(AppRoutes.categoryPicker);
    if (result != null) {
      setState(() {
        _categoryEmoji = result.emoji;
        _categoryLabel = result.label;
      });
    }
  }

  void _save() {
    final amount = double.tryParse(_amount) ?? 0;
    if (amount <= 0) {
      showToast(
        context,
        message: 'transactions.invalid_amount'.tr(),
        status: 'error',
      );
      return;
    }

    final transaction = Transaction(
      id: widget.initial?.id ??
          'txn-${DateTime.now().millisecondsSinceEpoch}',
      type: _type,
      amount: amount,
      categoryEmoji: _categoryEmoji,
      categoryLabel: _categoryLabel,
      source: widget.initial?.source ?? 'Cash',
      date: _date,
      note: _note,
      isAuto: widget.initial?.isAuto ?? false,
    );

    _submitted = true;
    final cubit = context.read<TransactionsCubit>();
    _isEdit
        ? cubit.updateTransaction(transaction)
        : cubit.addTransaction(transaction);
  }

  void _onStateChanged(BuildContext context, TransactionsState state) {
    if (!_submitted) return;
    switch (state.action) {
      case TransactionsAction.saveSuccess:
        _submitted = false;
        showToast(
          context,
          message: _isEdit
              ? 'transactions.updated'.tr()
              : 'transactions.saved'.tr(),
        );
        context.popOrGo(AppRoutes.home);
      case TransactionsAction.failure:
        _submitted = false;
        showToast(
          context,
          message: state.errorMessage ?? 'shared.something_wrong'.tr(),
          status: 'error',
        );
      case TransactionsAction.idle:
      case TransactionsAction.saving:
      case TransactionsAction.deleteSuccess:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();

    return BlocListener<TransactionsCubit, TransactionsState>(
      listenWhen: (previous, current) => previous.action != current.action,
      listener: _onStateChanged,
      child: Scaffold(
        appBar: AppTopBar(
          title: _isEdit
              ? 'transactions.edit_title'.tr()
              : 'transactions.title'.tr(),
          actions: [
            IconButton(
              onPressed: _addNote,
              icon: Icon(Icons.description_outlined,
                  color: context.colors.primary),
            ),
            SizedBox(width: 8.w),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 2.h, 20.w, 0),
                child: Column(
                  children: [
                    TransactionTypeToggle(
                      value: _type,
                      onChanged: (t) => setState(() => _type = t),
                    ),
                    SizedBox(height: 14.h),
                    TransactionDetails(
                      date: AppDate.fullDate(_date, locale),
                      amount: '$kCurrencySymbol $_amount',
                      category: '$_categoryEmoji $_categoryLabel',
                      hasNote: _note.isNotEmpty,
                      onTapDate: _pickDate,
                      onTapCategory: _pickCategory,
                      onAddNote: _addNote,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
                child: AmountKeypad(onKey: _onKey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

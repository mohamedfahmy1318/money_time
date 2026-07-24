import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/transactions/presentation/models/keypad_key.dart';
import 'package:mony_time/src/features/transactions/presentation/models/transaction_type.dart';
import 'package:mony_time/src/features/transactions/presentation/sections/amount_keypad.dart';
import 'package:mony_time/src/features/transactions/presentation/sections/transaction_details.dart';
import 'package:mony_time/src/features/transactions/presentation/sections/transaction_type_toggle.dart';
import 'package:mony_time/src/features/transactions/presentation/widgets/note_sheet.dart';

/// Add a transaction: pick a type, enter an amount on the keypad, and optionally
/// attach a note. UI-only for now — nothing is persisted yet.
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  TransactionType _type = TransactionType.expense;
  String _amount = '120.50';
  String _note = '';

  // Placeholder values until date/category pickers are wired up.
  static const _date = 'Wed, 15 Jul 2026';
  static const _category = '🛒 Groceries';

  /// True until the user first touches the keypad, so the seeded sample amount
  /// is cleared on the first digit rather than appended to.
  bool _amountPristine = true;

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

  void _save() {
    showToast(
      context,
      message: 'transactions.saved'.tr(),
      status: 'success',
    );
    context.popOrGo(AppRoutes.home);
  }

  void _comingSoon() => showToast(
        context,
        message: 'transactions.coming_soon'.tr(),
        status: 'info',
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'transactions.title'.tr(),
        actions: [
          IconButton(
            onPressed: _addNote,
            icon: Icon(Icons.description_outlined, color: context.colors.primary),
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
                    date: _date,
                    amount: 'E£ $_amount',
                    category: _category,
                    hasNote: _note.isNotEmpty,
                    onTapDate: _comingSoon,
                    onTapCategory: _comingSoon,
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
    );
  }
}

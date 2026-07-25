import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// A key press on the budget keypad.
enum BudgetKeyAction { digit, backspace, clear, save }

class BudgetKey {
  const BudgetKey(this.label, this.action);

  final String label;
  final BudgetKeyAction action;
}

/// The budget-limit keypad: digits with `⌫`, `C`, `.`, `00` and a gradient
/// Save key spanning two cells.
class BudgetKeypad extends StatelessWidget {
  const BudgetKeypad({super.key, required this.onKey});

  final void Function(BudgetKey key) onKey;

  static const List<List<BudgetKey>> _rows = [
    [
      BudgetKey('1', BudgetKeyAction.digit),
      BudgetKey('2', BudgetKeyAction.digit),
      BudgetKey('3', BudgetKeyAction.digit),
      BudgetKey('⌫', BudgetKeyAction.backspace),
    ],
    [
      BudgetKey('4', BudgetKeyAction.digit),
      BudgetKey('5', BudgetKeyAction.digit),
      BudgetKey('6', BudgetKeyAction.digit),
      BudgetKey('C', BudgetKeyAction.clear),
    ],
    [
      BudgetKey('7', BudgetKeyAction.digit),
      BudgetKey('8', BudgetKeyAction.digit),
      BudgetKey('9', BudgetKeyAction.digit),
      BudgetKey('.', BudgetKeyAction.digit),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.colors.outlineVariant,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 1.h,
        children: [
          for (final row in _rows)
            SizedBox(
              height: 48.h,
              child: Row(
                spacing: 1.w,
                children: [
                  for (final key in row)
                    Expanded(child: _key(context, key)),
                ],
              ),
            ),
          // Last row: 00 · 0 · Save (double width).
          SizedBox(
            height: 48.h,
            child: Row(
              spacing: 1.w,
              children: [
                Expanded(
                    child:
                        _key(context, const BudgetKey('00', BudgetKeyAction.digit))),
                Expanded(
                    child:
                        _key(context, const BudgetKey('0', BudgetKeyAction.digit))),
                Expanded(
                  flex: 2,
                  child: _key(
                    context,
                    BudgetKey('budgets.save'.tr(), BudgetKeyAction.save),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _key(BuildContext context, BudgetKey key) {
    final isSave = key.action == BudgetKeyAction.save;
    final isAccent = key.action == BudgetKeyAction.backspace ||
        key.action == BudgetKeyAction.clear;

    return GestureDetector(
      onTap: () => onKey(key),
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isSave ? null : context.colors.surfaceContainerLowest,
          gradient: isSave ? AppGradients.primaryButton : null,
        ),
        child: Center(
          child: Text(
            key.label,
            style: context.textTheme.titleMedium?.copyWith(
              color: isSave
                  ? Colors.white
                  : isAccent
                      ? context.colors.primary
                      : context.colors.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 17.sp,
            ),
          ),
        ),
      ),
    );
  }
}

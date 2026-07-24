import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/transactions/presentation/models/keypad_key.dart';
import 'package:mony_time/src/features/transactions/presentation/widgets/keypad_key_button.dart';

/// The calculator-style keypad pinned to the bottom of the add-transaction
/// screen. A rounded emerald-tinted tray with white keys separated by hairline
/// gaps. Reports each press up to the screen via [onKey].
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({super.key, required this.onKey});

  final ValueChanged<KeypadKey> onKey;

  static const List<List<KeypadKey>> _rows = [
    [
      KeypadKey('+', KeypadKeyKind.operator),
      KeypadKey('−', KeypadKeyKind.operator),
      KeypadKey('×', KeypadKeyKind.operator),
      KeypadKey('÷', KeypadKeyKind.operator),
    ],
    [
      KeypadKey('7', KeypadKeyKind.digit),
      KeypadKey('8', KeypadKeyKind.digit),
      KeypadKey('9', KeypadKeyKind.digit),
      KeypadKey('=', KeypadKeyKind.equals),
    ],
    [
      KeypadKey('4', KeypadKeyKind.digit),
      KeypadKey('5', KeypadKeyKind.digit),
      KeypadKey('6', KeypadKeyKind.digit),
      KeypadKey('.', KeypadKeyKind.digit),
    ],
    [
      KeypadKey('1', KeypadKeyKind.digit),
      KeypadKey('2', KeypadKeyKind.digit),
      KeypadKey('3', KeypadKeyKind.digit),
      KeypadKey('OK', KeypadKeyKind.ok),
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
                    Expanded(
                      child: KeypadKeyButton(
                        data: key,
                        onTap: () => onKey(key),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

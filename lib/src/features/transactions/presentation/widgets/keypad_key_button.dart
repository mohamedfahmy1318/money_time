import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/transactions/presentation/models/keypad_key.dart';

/// A single tappable key on the amount keypad. Digits render on a white cell,
/// operators/`=` in the brand emerald, and the confirm key as a filled gradient.
class KeypadKeyButton extends StatelessWidget {
  const KeypadKeyButton({super.key, required this.data, this.onTap});

  final KeypadKey data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isOk = data.kind == KeypadKeyKind.ok;
    final isAccent = data.kind == KeypadKeyKind.operator ||
        data.kind == KeypadKeyKind.equals;

    final color = isOk
        ? Colors.white
        : isAccent
            ? context.colors.primary
            : context.colors.onSurface;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isOk ? null : context.colors.surfaceContainerLowest,
          gradient: isOk ? AppGradients.primaryButton : null,
        ),
        child: Center(
          child: Text(
            data.label,
            style: context.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 17.sp,
            ),
          ),
        ),
      ),
    );
  }
}

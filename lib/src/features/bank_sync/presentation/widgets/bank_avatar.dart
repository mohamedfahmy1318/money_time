import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/bank_sync/domain/entities/bank.dart';
import 'package:mony_time/src/features/bank_sync/presentation/helpers/bank_display.dart';

/// A bank's monogram on its brand colour; a neutral SMS glyph when the sender
/// isn't a known bank.
class BankAvatar extends StatelessWidget {
  const BankAvatar({super.key, required this.bank, this.size});

  final Bank? bank;

  /// Tile edge; defaults to 38.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final s = size ?? 38.r;
    final b = bank;

    return Container(
      width: s,
      height: s,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: s * 0.1),
      decoration: BoxDecoration(
        color: b?.color ?? context.colors.surface,
        borderRadius: BorderRadius.circular(s * 0.34),
      ),
      child: b == null
          ? Icon(
              Icons.sms_outlined,
              size: s * 0.46,
              color: context.colors.onSurfaceVariant,
            )
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                b.shortName,
                maxLines: 1,
                style: context.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: s * 0.3,
                ),
              ),
            ),
    );
  }
}

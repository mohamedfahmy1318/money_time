import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// A muted label over a bold coloured value — the Income / Exp. / Total
/// columns on the ledger and filter screens.
class AmountStat extends StatelessWidget {
  const AmountStat({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
            fontWeight: FontWeight.w400,
            fontSize: 10.8.sp,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          value,
          style: context.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13.8.sp,
            letterSpacing: -0.14,
          ),
        ),
      ],
    );
  }
}

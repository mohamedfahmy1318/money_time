import '../../imports/core_imports.dart';

/// Income / Expense pill toggle — a thin, enum-typed wrapper over
/// [SegmentedTabs]. Figma flips the two segments and swaps the pill style
/// between screens, so both are configurable.
class TransactionTypeToggle extends StatelessWidget {
  const TransactionTypeToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.style = SegmentedToggleStyle.gradient,
    this.order = const [TransactionType.income, TransactionType.expense],
  });

  final TransactionType value;
  final ValueChanged<TransactionType> onChanged;
  final SegmentedToggleStyle style;
  final List<TransactionType> order;

  @override
  Widget build(BuildContext context) {
    return SegmentedTabs(
      labels: [for (final type in order) type.label],
      selectedIndex: order.indexOf(value),
      style: style,
      onChanged: (i) => onChanged(order[i]),
    );
  }
}

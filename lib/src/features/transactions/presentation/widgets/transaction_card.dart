import 'package:mony_time/src/imports/core_imports.dart';

/// White rounded card stacking transaction rows with hairline dividers —
/// the container used by the daily list, the calendar day card and search
/// results.
class TransactionCard extends StatelessWidget {
  const TransactionCard({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return AppSoftCard(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: context.colors.outlineVariant,
              ),
            rows[i],
          ],
        ],
      ),
    );
  }
}

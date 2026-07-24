import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/home/presentation/models/home_data.dart';
import 'package:mony_time/src/features/home/presentation/widgets/section_header.dart';
import 'package:mony_time/src/features/home/presentation/widgets/transaction_tile.dart';

/// "Recent" header plus a card listing the latest transactions.
class RecentSection extends StatelessWidget {
  const RecentSection({super.key, required this.transactions});

  final List<HomeTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(
          title: 'home.recent'.tr(),
          action: 'home.see_all'.tr(),
          onAction: () {},
        ),
        SizedBox(height: 12.h),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerLowest,
            borderRadius: AppBorders.xl,
            border: Border.all(color: context.colors.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: context.colors.onSurface.withValues(alpha: 0.05),
                offset: Offset(0, 4.h),
                blurRadius: 7.r,
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < transactions.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: context.colors.outlineVariant,
                  ),
                TransactionTile(transaction: transactions[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

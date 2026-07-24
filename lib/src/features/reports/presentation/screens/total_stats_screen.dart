import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/reports/presentation/sections/total_stats_view.dart';
import 'package:mony_time/src/features/reports/presentation/widgets/monthly_dropdown.dart';

/// Pushed net-worth detail screen (a two-line title and the period picker over
/// the reusable [TotalStatsView]).
class TotalStatsScreen extends StatelessWidget {
  const TotalStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'reports.total_stats'.tr(),
        titleWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'reports.total_stats'.tr(),
              style: context.textTheme.titleLarge?.copyWith(
                color: context.colors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
            Text(
              'reports.net_worth_trend'.tr(),
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: 12.5.sp,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20.w),
            child: const Center(child: MonthlyDropdown()),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: TotalStatsView(padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h)),
      ),
    );
  }
}

import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/reports/presentation/models/report_data.dart';
import 'package:mony_time/src/features/reports/presentation/widgets/net_worth_line_chart.dart';
import 'package:mony_time/src/features/reports/presentation/widgets/report_list_row.dart';

/// Net-worth trend body: big total + area chart, a period switcher, and the
/// assets row. Reused by the Reports "Budget" tab (inline) and the pushed
/// [TotalStatsScreen].
class TotalStatsView extends StatefulWidget {
  const TotalStatsView({super.key, required this.padding});

  final EdgeInsetsGeometry padding;

  @override
  State<TotalStatsView> createState() => _TotalStatsViewState();
}

class _TotalStatsViewState extends State<TotalStatsView> {
  int _period = 1; // Weekly / Monthly / Annually — Monthly per Figma.

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: widget.padding,
      children: [
        AppSoftCard(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ReportSampleData.netWorth,
                style: context.textTheme.headlineSmall?.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 23.8.sp,
                  letterSpacing: -0.24,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                ReportSampleData.netWorthChange,
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 10.h),
              const NetWorthLineChart(
                points: ReportSampleData.netWorthPoints,
                months: ReportSampleData.netWorthMonths,
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        SegmentedTabs(
          labels: [
            'reports.weekly'.tr(),
            'reports.monthly'.tr(),
            'reports.annually'.tr(),
          ],
          selectedIndex: _period,
          onChanged: (i) => setState(() => _period = i),
        ),
        SizedBox(height: 14.h),
        AppSoftCard(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
          child: ReportListRow(
            entry: ReportSampleData.assets,
            amountColor: context.colors.tertiary,
          ),
        ),
      ],
    );
  }
}

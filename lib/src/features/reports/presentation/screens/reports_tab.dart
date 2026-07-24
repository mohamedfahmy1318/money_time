import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/reports/presentation/sections/reports_note_view.dart';
import 'package:mony_time/src/features/reports/presentation/sections/reports_stats_view.dart';
import 'package:mony_time/src/features/reports/presentation/sections/total_stats_view.dart';
import 'package:mony_time/src/features/reports/presentation/widgets/monthly_dropdown.dart';

/// Reports bottom-nav tab: a "Reports" header with the period picker over a
/// Stats / Budget / Note switcher. Budget reuses the net-worth [TotalStatsView].
class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
            child: Row(
              children: [
                Text(
                  'reports.title'.tr(),
                  style: context.textTheme.titleLarge?.copyWith(
                    color: context.colors.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
                const Spacer(),
                const MonthlyDropdown(),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: SegmentedTabs(
              labels: [
                'reports.stats'.tr(),
                'reports.budget'.tr(),
                'reports.note'.tr(),
              ],
              selectedIndex: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                const ReportsStatsView(),
                TotalStatsView(padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 100.h)),
                const ReportsNoteView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

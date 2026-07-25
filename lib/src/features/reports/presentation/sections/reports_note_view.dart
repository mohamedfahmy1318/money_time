import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/reports/presentation/models/report_data.dart';
import 'package:mony_time/src/features/reports/presentation/widgets/report_list_row.dart';

/// Note sub-tab: an Income/Expense underline filter over the tagged
/// transaction list.
class ReportsNoteView extends StatefulWidget {
  const ReportsNoteView({super.key});

  @override
  State<ReportsNoteView> createState() => _ReportsNoteViewState();
}

class _ReportsNoteViewState extends State<ReportsNoteView> {
  int _filter = 1; // 0 = income, 1 = expense (Expense active per Figma).

  @override
  Widget build(BuildContext context) {
    const entries = ReportSampleData.noteEntries;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: UnderlineTabs(
            labels: ['reports.income'.tr(), 'reports.expense'.tr()],
            colors: [context.colors.tertiary, context.colors.error],
            selectedIndex: _filter,
            onChanged: (i) => setState(() => _filter = i),
          ),
        ),
        SizedBox(height: 14.h),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 100.h),
            children: [
              AppSoftCard(
                child: Column(
                  children: [
                    for (var i = 0; i < entries.length; i++) ...[
                      if (i > 0)
                        Divider(height: 1, thickness: 1, color: context.colors.outlineVariant),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                        child: ReportListRow(
                          entry: entries[i],
                          amountColor: context.colors.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

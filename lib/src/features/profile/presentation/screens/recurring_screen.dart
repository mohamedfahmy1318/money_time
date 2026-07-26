import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/profile/presentation/models/recurring_sample.dart';
import 'package:mony_time/src/features/profile/presentation/widgets/setting_value_row.dart';
import 'package:mony_time/src/features/profile/presentation/widgets/settings_section.dart';
import 'package:mony_time/src/features/transactions/presentation/widgets/transaction_row.dart';

/// Repeat / Recurring: the reflection-timing row over the list of active
/// recurring rules. Display-only for now — the add action and rows surface a
/// "coming soon" toast.
class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  void _comingSoon(BuildContext context) =>
      showToast(context, message: 'profile.coming_soon'.tr(), status: 'info');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'recurring.title'.tr(),
        actions: [
          IconButton(
            onPressed: () => _comingSoon(context),
            icon: Icon(Icons.add_rounded, size: 24.sp),
            color: context.colors.onSurface,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(top: 2.h, bottom: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingValueRow(
                label: 'recurring.timing'.tr(),
                value: 'recurring.timing_value'.tr(),
                showChevron: true,
                onTap: () => _comingSoon(context),
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: SettingsSection(
                  title: 'recurring.active'.tr(),
                  rows: [
                    for (final item in RecurringSampleData.items)
                      TransactionRow(
                        transaction: item,
                        onTap: () => _comingSoon(context),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

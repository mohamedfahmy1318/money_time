import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/profile/presentation/widgets/setting_value_row.dart';

/// Transaction Settings: a flat list of preference rows, each showing its
/// current value on the trailing edge. Display-only for now — tapping a row
/// surfaces a "coming soon" toast until the pickers land.
class TransactionSettingsScreen extends StatelessWidget {
  const TransactionSettingsScreen({super.key});

  void _comingSoon(BuildContext context) =>
      showToast(context, message: 'profile.coming_soon'.tr(), status: 'info');

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('transaction_settings.monthly_start_date', '1'),
      ('transaction_settings.weekly_start_day', 'transaction_settings.value_sunday'.tr()),
      ('transaction_settings.carry_over', 'transaction_settings.value_off'.tr()),
      ('transaction_settings.period_setting', 'transaction_settings.value_monthly'.tr()),
      ('transaction_settings.income_expense_color', 'transaction_settings.value_default'.tr()),
      ('transaction_settings.autocomplete', 'transaction_settings.value_on'.tr()),
      ('transaction_settings.start_screen', 'transaction_settings.value_daily'.tr()),
      ('transaction_settings.input_order', 'transaction_settings.value_from_amount'.tr()),
    ];

    return Scaffold(
      appBar: AppTopBar(title: 'settings.transaction_settings'.tr()),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(top: 2.h, bottom: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < rows.length; i++)
                SettingValueRow(
                  label: rows[i].$1.tr(),
                  value: rows[i].$2,
                  showDivider: i < rows.length - 1,
                  onTap: () => _comingSoon(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

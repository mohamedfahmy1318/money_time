import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/auth/presentation/helpers/auth_actions.dart';
import 'package:mony_time/src/features/profile/presentation/widgets/settings_section.dart';
import 'package:mony_time/src/features/profile/presentation/widgets/profile_menu_row.dart';

/// Settings: grouped preference rows (Transactions, Categories & Accounts, App).
/// Navigation-ready rows push their screen; the rest surface a "coming soon"
/// toast until their feature lands.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _comingSoon(BuildContext context) =>
      showToast(context, message: 'profile.coming_soon'.tr(), status: 'info');

  @override
  Widget build(BuildContext context) {
    final language = context.locale.languageCode == 'ar'
        ? 'settings.arabic'.tr()
        : 'settings.english'.tr();

    return Scaffold(
      appBar: AppTopBar(
        title: 'settings.title'.tr(),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Center(
              child: Text(
                'v1.0',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontSize: 11.sp,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsSection(
                title: 'settings.section_transactions'.tr(),
                rows: [
                  ProfileMenuRow(
                    icon: Icons.receipt_long_outlined,
                    label: 'settings.transaction_settings'.tr(),
                    onTap: () => context.push(AppRoutes.transactionSettings),
                  ),
                  ProfileMenuRow(
                    icon: Icons.repeat_rounded,
                    label: 'settings.repeat_setting'.tr(),
                    onTap: () => context.push(AppRoutes.recurring),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              SettingsSection(
                title: 'settings.section_categories'.tr(),
                rows: [
                  ProfileMenuRow(
                    icon: Icons.add_rounded,
                    label: 'settings.income_categories'.tr(),
                    onTap: () => context.guardedPush(
                      AppRoutes.categoryManage,
                      extra: TransactionType.income,
                    ),
                  ),
                  ProfileMenuRow(
                    icon: Icons.remove_rounded,
                    label: 'settings.expense_categories'.tr(),
                    onTap: () => context.guardedPush(
                      AppRoutes.categoryManage,
                      extra: TransactionType.expense,
                    ),
                  ),
                  ProfileMenuRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'settings.budget_categories'.tr(),
                    onTap: () => context.push(AppRoutes.budgetSettings),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              SettingsSection(
                title: 'settings.section_app'.tr(),
                rows: [
                  ProfileMenuRow(
                    icon: Icons.currency_exchange_rounded,
                    label: 'settings.main_currency'.tr(),
                    onTap: () => context.push(AppRoutes.mainCurrency),
                    trailing: _valueLabel(context, 'EGP'),
                  ),
                  ProfileMenuRow(
                    icon: Icons.language_rounded,
                    label: 'settings.language'.tr(),
                    onTap: () => _comingSoon(context),
                    trailing: _valueLabel(context, language),
                  ),
                  ProfileMenuRow(
                    icon: Icons.palette_outlined,
                    label: 'settings.appearance'.tr(),
                    onTap: () => context.push(AppRoutes.appearance),
                    trailing:
                        _valueLabel(context, 'settings.appearance_system'.tr()),
                  ),
                  ProfileMenuRow(
                    icon: Icons.alarm_rounded,
                    label: 'settings.reminder'.tr(),
                    onTap: () => context.push(AppRoutes.reminder),
                  ),
                  ProfileMenuRow(
                    icon: Icons.notifications_outlined,
                    label: 'settings.notifications'.tr(),
                    onTap: () => context.push(AppRoutes.notifications),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _valueLabel(BuildContext context, String value) => Text(
        value,
        style: context.textTheme.labelMedium?.copyWith(
          color: context.colors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 13.sp,
        ),
      );
}

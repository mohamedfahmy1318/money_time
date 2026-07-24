import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/profile/presentation/widgets/profile_menu_row.dart';
import 'package:mony_time/src/features/profile/presentation/widgets/soft_pill.dart';

/// The profile settings menu: account rows plus the connected-shortcut row.
class ProfileMenuCard extends StatelessWidget {
  const ProfileMenuCard({super.key});

  void _comingSoon(BuildContext context) =>
      showToast(context, message: 'profile.coming_soon'.tr(), status: 'info');

  @override
  Widget build(BuildContext context) {
    return AppSoftCard(
      child: Column(
        children: [
          ProfileMenuRow(
            icon: Icons.person_outline_rounded,
            label: 'profile.personal_info'.tr(),
            onTap: () => _comingSoon(context),
          ),
          _divider(context),
          ProfileMenuRow(
            icon: Icons.settings_outlined,
            label: 'profile.settings'.tr(),
            onTap: () => _comingSoon(context),
          ),
          _divider(context),
          ProfileMenuRow(
            icon: Icons.shield_outlined,
            label: 'profile.security'.tr(),
            onTap: () => _comingSoon(context),
          ),
          _divider(context),
          ProfileMenuRow(
            icon: Icons.cloud_sync_outlined,
            label: 'profile.backup'.tr(),
            onTap: () => _comingSoon(context),
          ),
          _divider(context),
          ProfileMenuRow(
            icon: Icons.bolt_rounded,
            label: 'profile.shortcut_link'.tr(),
            onTap: () => context.push(AppRoutes.connectShortcuts),
            trailing: SoftPill(
              label: 'profile.connected'.tr(),
              trailingIcon: Icons.check_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        color: context.colors.outlineVariant,
      );
}

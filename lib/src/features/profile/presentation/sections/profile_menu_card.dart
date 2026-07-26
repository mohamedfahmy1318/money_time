import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/auth/presentation/cubits/session_cubit.dart';
import 'package:mony_time/src/features/auth/presentation/helpers/auth_actions.dart';
import 'package:mony_time/src/features/profile/presentation/widgets/profile_menu_row.dart';
import 'package:mony_time/src/features/profile/presentation/widgets/soft_pill.dart';

/// The profile settings menu: account rows plus the connected-shortcut row.
class ProfileMenuCard extends StatelessWidget {
  const ProfileMenuCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isAuthed = context.select<SessionCubit, bool>(
      (c) => c.state.status == SessionStatus.authenticated,
    );

    return AppSoftCard(
      child: Column(
        children: [
          ProfileMenuRow(
            icon: Icons.person_outline_rounded,
            label: 'profile.personal_info'.tr(),
            onTap: () => context.guardedPush(AppRoutes.personalInfo),
          ),
          _divider(context),
          ProfileMenuRow(
            icon: Icons.settings_outlined,
            label: 'profile.settings'.tr(),
            onTap: () => context.push(AppRoutes.settings),
          ),
          _divider(context),
          ProfileMenuRow(
            icon: Icons.shield_outlined,
            label: 'profile.security'.tr(),
            onTap: () => context.guardedPush(AppRoutes.security),
          ),
          _divider(context),
          ProfileMenuRow(
            icon: Icons.cloud_sync_outlined,
            label: 'profile.backup'.tr(),
            onTap: () => context.guardedPush(AppRoutes.backup),
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
          if (isAuthed) ...[
            _divider(context),
            ProfileMenuRow(
              icon: Icons.logout_rounded,
              label: 'profile.log_out'.tr(),
              onTap: () => context.read<SessionCubit>().logout(),
            ),
          ],
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

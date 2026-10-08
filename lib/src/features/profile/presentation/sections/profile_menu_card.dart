import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/auth/presentation/cubits/session_cubit.dart';
import 'package:mony_time/src/features/auth/presentation/helpers/auth_actions.dart';
import 'package:mony_time/src/features/bank_sync/presentation/cubits/bank_sync_cubit.dart';
import 'package:mony_time/src/features/profile/presentation/widgets/profile_menu_row.dart';
import 'package:mony_time/src/features/profile/presentation/widgets/soft_pill.dart';

/// The profile settings menu: account rows plus the bank-messages link row.
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
            icon: Icons.sms_outlined,
            label: 'profile.shortcut_link'.tr(),
            onTap: () => context.push(AppRoutes.bankLink),
            trailing: const _BankLinkStatus(),
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

/// Live link state on the bank-messages row: pending count, Connected, or a
/// muted Connect prompt.
class _BankLinkStatus extends StatelessWidget {
  const _BankLinkStatus();

  @override
  Widget build(BuildContext context) {
    final (connected, pending) = context.select<BankSyncCubit, (bool, int)>(
      (c) => (c.state.isConnected, c.state.summary.pendingCount),
    );

    if (connected && pending > 0) {
      return SoftPill(
        label: 'bank_sync.new_count'.tr(namedArgs: {'count': '$pending'}),
        leadingIcon: Icons.mark_chat_unread_outlined,
      );
    }
    if (connected) {
      return SoftPill(
        label: 'profile.connected'.tr(),
        trailingIcon: Icons.check_rounded,
      );
    }
    return Text(
      'bank_sync.connect'.tr(),
      style: context.textTheme.labelMedium?.copyWith(
        color: context.colors.primary,
        fontWeight: FontWeight.bold,
        fontSize: 12.sp,
      ),
    );
  }
}

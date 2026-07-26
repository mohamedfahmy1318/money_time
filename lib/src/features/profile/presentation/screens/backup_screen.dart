import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/profile/presentation/widgets/settings_section.dart';

/// Backup & Data: the cloud-backup status, backup/restore actions, provider
/// choice, and export. Display-only for the UI phase — actions toast, provider
/// selection is local.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  int _provider = 0;

  void _comingSoon() =>
      showToast(context, message: 'profile.coming_soon'.tr(), status: 'info');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'backup.title'.tr()),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 2.h, 20.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroCard(),
              SizedBox(height: 20.h),
              AppSoftCard(
                child: Column(
                  children: [
                    _ActionRow(
                      icon: Icons.cloud_sync_outlined,
                      label: 'backup.back_up_now'.tr(),
                      onTap: _comingSoon,
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: context.colors.outlineVariant,
                    ),
                    _ActionRow(
                      icon: Icons.restore_rounded,
                      label: 'backup.restore'.tr(),
                      onTap: _comingSoon,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              SettingsSection(
                title: 'backup.provider'.tr(),
                rows: [
                  _ProviderRow(
                    label: '☁️  iCloud',
                    selected: _provider == 0,
                    onTap: () => setState(() => _provider = 0),
                  ),
                  _ProviderRow(
                    label: '🟢  Google Drive',
                    selected: _provider == 1,
                    onTap: () => setState(() => _provider = 1),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              SettingsSection(
                title: 'backup.export'.tr(),
                rows: [
                  _ActionRow(
                    icon: Icons.table_chart_outlined,
                    label: 'backup.export_csv'.tr(),
                    onTap: _comingSoon,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final light = Colors.white.withValues(alpha: 0.85);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.primaryButton,
        borderRadius: BorderRadius.circular(26.r),
        boxShadow: [
          BoxShadow(
            color: context.colors.primary.withValues(alpha: 0.4),
            offset: Offset(0, 18.h),
            blurRadius: 30.r,
            spreadRadius: -14.r,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26.r),
        child: Stack(
          children: [
            PositionedDirectional(
              top: -30.r,
              end: -30.r,
              child: Container(
                width: 140.r,
                height: 140.r,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'backup.cloud_backup'.tr(),
                    style: context.textTheme.labelMedium?.copyWith(
                      color: light,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'backup.last_backup'.tr(),
                    style: context.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'backup.auto_backup'.tr(),
                    style: context.textTheme.labelSmall?.copyWith(
                      color: light,
                      fontSize: 11.sp,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 16.h),
        child: Row(
          children: [
            Icon(icon, size: 18.sp, color: context.colors.primary),
            SizedBox(width: 13.w),
            Expanded(
              child: Text(
                label,
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5.sp,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18.sp,
              color: context.colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderRow extends StatelessWidget {
  const _ProviderRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5.sp,
                ),
              ),
            ),
            if (selected)
              Icon(
                Icons.check_rounded,
                size: 18.sp,
                color: context.colors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

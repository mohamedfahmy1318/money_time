import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/setup/presentation/widgets/permission_row.dart';
import 'package:mony_time/src/features/setup/presentation/widgets/setup_card.dart';

/// Final first-run screen: opt into the permissions Money Time uses. The
/// toggles are presentation-only for now — both actions hand off to login.
class EnableFeaturesScreen extends StatefulWidget {
  const EnableFeaturesScreen({super.key});

  @override
  State<EnableFeaturesScreen> createState() => _EnableFeaturesScreenState();
}

class _EnableFeaturesScreenState extends State<EnableFeaturesScreen> {
  bool _notifications = true;
  bool _shortcuts = true;
  bool _personalisation = false;

  void _finish() => context.go(AppRoutes.login);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 12.h),
                      const _HeaderIcon(),
                      SizedBox(height: 14.h),
                      Text(
                        'setup.enable_title'.tr(),
                        textAlign: TextAlign.center,
                        style: context.textTheme.titleLarge?.copyWith(
                          color: context.colors.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 21.sp,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'setup.enable_subtitle'.tr(),
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                          fontSize: 12.5.sp,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      SetupCard(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15.w),
                          child: Column(
                            children: [
                              PermissionRow(
                                iconColor: context.colors.primary,
                                emoji: '🔔',
                                title: 'setup.notifications_title'.tr(),
                                description: 'setup.notifications_desc'.tr(),
                                value: _notifications,
                                onChanged: (v) =>
                                    setState(() => _notifications = v),
                              ),
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: context.colors.outlineVariant,
                              ),
                              PermissionRow(
                                iconColor: context.colors.onSurface,
                                emoji: '⚡',
                                title: 'setup.shortcuts_title'.tr(),
                                description: 'setup.shortcuts_desc'.tr(),
                                value: _shortcuts,
                                onChanged: (v) =>
                                    setState(() => _shortcuts = v),
                              ),
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: context.colors.outlineVariant,
                              ),
                              PermissionRow(
                                iconColor: context.colors.tertiary,
                                emoji: '📊',
                                title: 'setup.personalisation_title'.tr(),
                                description: 'setup.personalisation_desc'.tr(),
                                value: _personalisation,
                                onChanged: (v) =>
                                    setState(() => _personalisation = v),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
              AppGradientButton(
                label: 'setup.allow_continue'.tr(),
                onPressed: _finish,
              ),
              SizedBox(height: 4.h),
              TextButton(
                onPressed: _finish,
                child: Text(
                  'setup.maybe_later'.tr(),
                  style: context.textTheme.labelMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5.sp,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66.r,
      height: 66.r,
      decoration: const BoxDecoration(
        gradient: AppGradients.primaryButton,
        borderRadius: AppBorders.xl,
      ),
      alignment: Alignment.center,
      child: Icon(Icons.shield_outlined, color: Colors.white, size: 30.r),
    );
  }
}

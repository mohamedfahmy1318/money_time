import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/auth/domain/entities/user.dart';

/// Post-auth prompt to connect Apple Shortcuts. Both actions carry the freshly
/// authenticated [user] forward to the "all set" screen; the session isn't
/// marked authenticated until the very end of the funnel.
class ConnectShortcutsScreen extends StatelessWidget {
  const ConnectShortcutsScreen({super.key, this.user});

  final AppUser? user;

  void _next(BuildContext context) =>
      context.go(AppRoutes.allSet, extra: user);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 22.w),
          child: Column(
            children: [
              SizedBox(height: 28.h),
              SvgPicture.asset(
                AppAssets.welcomeShortcuts,
                width: 170.w,
                height: 146.h,
              ),
              SizedBox(height: 52.h),
              Text(
                'welcome.shortcuts_title'.tr(),
                textAlign: TextAlign.center,
                style: context.textTheme.headlineSmall?.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 25.sp,
                  letterSpacing: -0.5,
                  height: 1.15,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'welcome.shortcuts_subtitle'.tr(),
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontSize: 14.sp,
                  height: 21.7 / 14,
                ),
              ),
              const Spacer(),
              AppGradientButton(
                label: 'welcome.connect_shortcuts'.tr(),
                onPressed: () => _next(context),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}

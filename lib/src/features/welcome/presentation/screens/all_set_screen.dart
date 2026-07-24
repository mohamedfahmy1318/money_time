import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/auth/domain/entities/user.dart';
import 'package:mony_time/src/features/auth/presentation/cubits/session_cubit.dart';

/// Final post-auth screen. "Enter Money Time" commits the user to the session,
/// which flips the status to authenticated — `SessionListenerWrapper` then
/// performs the redirect to home.
class AllSetScreen extends StatelessWidget {
  const AllSetScreen({super.key, this.user});

  final AppUser? user;

  String _title() {
    final name = user?.name?.trim();
    if (name == null || name.isEmpty) {
      return 'welcome.all_set_title_generic'.tr();
    }
    // Keep only the first name to match the Figma greeting.
    final firstName = name.split(' ').first;
    return 'welcome.all_set_title'.tr(namedArgs: {'name': firstName});
  }

  void _enter(BuildContext context) {
    final u = user;
    if (u != null) {
      context.read<SessionCubit>().setUser(u);
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 22.w),
          child: Column(
            children: [
              SizedBox(height: 52.h),
              SvgPicture.asset(
                AppAssets.welcomeSuccess,
                width: 150.w,
                height: 130.h,
              ),
              SizedBox(height: 52.h),
              Text(
                _title(),
                textAlign: TextAlign.center,
                style: context.textTheme.headlineSmall?.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 25.sp,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                'welcome.all_set_subtitle'.tr(),
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontSize: 14.sp,
                  height: 21.7 / 14,
                ),
              ),
              const Spacer(),
              AppGradientButton(
                label: 'welcome.enter_money_time'.tr(),
                onPressed: () => _enter(context),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}

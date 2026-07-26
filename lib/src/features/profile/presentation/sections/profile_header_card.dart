import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/auth/presentation/cubits/session_cubit.dart';
import 'package:mony_time/src/features/profile/presentation/widgets/soft_pill.dart';

/// The profile card: a gradient avatar with the user's initial, their name, and
/// the membership badge.
class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionCubit>().state.user;
    final name = (user?.name?.trim().isNotEmpty ?? false)
        ? user!.name!.trim()
        : 'profile.guest'.tr();
    final initial = name.characters.first.toUpperCase();

    return AppSoftCard(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Column(
        children: [
          Container(
            width: 72.r,
            height: 72.r,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: AppGradients.primaryButton,
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: context.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 26.sp,
              ),
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            name,
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colors.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 8.h),
          if (user == null)
            _SignInButton()
          else
            SoftPill(
              label: 'profile.premium'.tr(),
              leadingIcon: Icons.star_rounded,
            ),
        ],
      ),
    );
  }
}

/// Guest call-to-action: routes to the sign-in flow.
class _SignInButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.login),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 9.h),
        decoration: const BoxDecoration(
          gradient: AppGradients.primaryButton,
          borderRadius: AppBorders.full,
        ),
        child: Text(
          'profile.sign_in'.tr(),
          style: context.textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12.5.sp,
          ),
        ),
      ),
    );
  }
}

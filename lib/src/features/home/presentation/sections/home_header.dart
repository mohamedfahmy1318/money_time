import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/auth/presentation/cubits/session_cubit.dart';

/// Dashboard greeting: time-of-day salutation, the signed-in user's name, and
/// a notifications bell.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionCubit>().state.user;
    final name = (user?.name?.trim().isNotEmpty ?? false)
        ? user!.name!.trim()
        : 'home.there'.tr();

    return Padding(
      padding: EdgeInsets.fromLTRB(22.w, 12.h, 22.w, 8.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'home.greeting'.tr(),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  name,
                  style: context.textTheme.titleLarge?.copyWith(
                    color: context.colors.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.notifications_none_rounded,
            color: context.colors.onSurface,
            size: 22.sp,
          ),
        ],
      ),
    );
  }
}

import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/profile/presentation/sections/profile_header_card.dart';
import 'package:mony_time/src/features/profile/presentation/sections/profile_menu_card.dart';

/// Profile bottom-nav tab: the user card over the account settings menu.
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
            child: Text(
              'profile.title'.tr(),
              style: context.textTheme.titleLarge?.copyWith(
                color: context.colors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 100.h),
              child: Column(
                children: [
                  const ProfileHeaderCard(),
                  SizedBox(height: 16.h),
                  const ProfileMenuCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/auth/domain/entities/user.dart';
import 'package:mony_time/src/features/auth/presentation/cubits/session_cubit.dart';
import 'package:mony_time/src/features/profile/presentation/widgets/info_field_row.dart';

/// Personal Info: the editable account card (name / email / phone) over the
/// gradient avatar, with a bottom-pinned Save action. Presentation-only — Save
/// syncs the edited name/email back into [SessionCubit] (no profile backend
/// yet).
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    final user = context.read<SessionCubit>().state.user;
    _name = TextEditingController(text: user?.name ?? '');
    _email = TextEditingController(text: user?.email ?? '');
    _phone = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    final session = context.read<SessionCubit>();
    final current = session.state.user;
    if (current != null) {
      session.setUser(AppUser(
        id: current.id,
        email: _email.text.trim(),
        name: _name.text.trim(),
        photoUrl: current.photoUrl,
      ));
    }
    context.pop();
    showGlobalToast(message: 'personal_info.saved'.tr());
  }

  @override
  Widget build(BuildContext context) {
    final name = _name.text.trim();
    final initial =
        name.isNotEmpty ? name.characters.first.toUpperCase() : 'A';

    return Scaffold(
      appBar: AppTopBar(title: 'personal_info.title'.tr()),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
                child: Column(
                  children: [
                    _Avatar(
                      initial: initial,
                      onEdit: () => showToast(
                        context,
                        message: 'personal_info.photo_soon'.tr(),
                        status: 'info',
                      ),
                    ),
                    SizedBox(height: 18.h),
                    AppSoftCard(
                      child: Column(
                        children: [
                          InfoFieldRow(
                            label: 'personal_info.name'.tr(),
                            controller: _name,
                            hint: 'personal_info.name_hint'.tr(),
                          ),
                          InfoFieldRow(
                            label: 'personal_info.email'.tr(),
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          InfoFieldRow(
                            label: 'personal_info.phone'.tr(),
                            controller: _phone,
                            hint: 'personal_info.phone_hint'.tr(),
                            keyboardType: TextInputType.phone,
                          ),
                          InfoFieldRow(
                            label: 'personal_info.plan'.tr(),
                            showDivider: false,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 15.sp,
                                  color: context.colors.primary,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'personal_info.premium'.tr(),
                                  style: context.textTheme.titleSmall?.copyWith(
                                    color: context.colors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
              child: AppGradientButton(
                label: 'personal_info.save'.tr(),
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The gradient avatar with the user's initial and a small camera edit badge
/// pinned to its trailing-bottom corner.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial, required this.onEdit});

  final String initial;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80.r,
      height: 80.r,
      child: Stack(
        children: [
          Container(
            width: 80.r,
            height: 80.r,
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
          PositionedDirectional(
            end: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: onEdit,
              child: Container(
                width: 28.r,
                height: 28.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: Colors.white, width: 2.r),
                ),
                child: Icon(
                  Icons.photo_camera_rounded,
                  size: 14.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

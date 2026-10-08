import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/bank_sync/presentation/widgets/note_banner.dart';

/// Android: the link captures on this phone but SMS access is off (refused
/// in the wizard, revoked in settings, or the link was made on a previous
/// install) — nothing would be captured, so say so and offer the fix.
/// Re-checks when the app comes back from settings; hides itself once
/// access is granted.
class SmsAccessBanner extends StatefulWidget {
  const SmsAccessBanner({super.key});

  @override
  State<SmsAccessBanner> createState() => _SmsAccessBannerState();
}

class _SmsAccessBannerState extends State<SmsAccessBanner> {
  late final AppLifecycleListener _lifecycle;
  PermissionStatus? _status;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _check);
    _check();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final result = await PermissionService.instance.checkStatus(Permission.sms);
    if (!mounted) return;
    setState(() => _status = result.fold((_) => null, (s) => s));
  }

  Future<void> _fix() async {
    if (_status?.isPermanentlyDenied ?? false) {
      await PermissionService.instance.openSettings();
      return;
    }
    final result = await PermissionService.instance.request(Permission.sms);
    if (!mounted) return;
    setState(() => _status = result.fold((_) => _status, (s) => s));
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (status == null || status.isGranted) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NoteBanner(
            icon: Icons.sms_failed_outlined,
            tone: NoteTone.warning,
            title: 'bank_sync.sms_off_title'.tr(),
            text: 'bank_sync.sms_off_desc'.tr(),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: _fix,
              child: Text(
                status.isPermanentlyDenied
                    ? 'bank_sync.open_settings'.tr()
                    : 'bank_sync.allow_sms'.tr(),
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/auth/presentation/helpers/auth_actions.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_link.dart';
import 'package:mony_time/src/features/bank_sync/presentation/cubits/bank_sync_cubit.dart';
import 'package:mony_time/src/features/bank_sync/presentation/helpers/bank_import_flow.dart';
import 'package:mony_time/src/features/bank_sync/presentation/sections/link_intro_section.dart';
import 'package:mony_time/src/features/bank_sync/presentation/sections/link_status_hero.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/bank_row.dart';
import 'package:mony_time/src/features/profile/presentation/widgets/profile_menu_row.dart';
import 'package:mony_time/src/features/profile/presentation/widgets/settings_section.dart';
import 'package:mony_time/src/features/setup/presentation/widgets/pill_toggle.dart';

/// The bank-SMS link hub (Profile → Bank messages). Before linking it pitches
/// the feature and starts setup; once linked it shows the live status and
/// manages import mode, banks, the iOS Shortcut and disconnecting.
class BankLinkScreen extends StatefulWidget {
  const BankLinkScreen({super.key});

  @override
  State<BankLinkScreen> createState() => _BankLinkScreenState();
}

class _BankLinkScreenState extends State<BankLinkScreen> with BankImportFlow {
  /// True after this screen fired a settings change — guards the shared
  /// cubit's action stream.
  bool _awaiting = false;
  bool _disconnecting = false;

  @override
  void onImported(int count) =>
      showToast(context, message: 'bank_sync.added_count'.plural(count));

  void _toggleBank(BankSyncState state, String bankId) {
    final linked = state.link.bankIds;
    if (linked.length == 1 && linked.contains(bankId)) {
      showToast(
        context,
        message: 'bank_sync.keep_one_bank'.tr(),
        status: 'warning',
      );
      return;
    }
    _awaiting = true;
    context.read<BankSyncCubit>().toggleBank(bankId);
  }

  void _setAutomatic(bool automatic) {
    _awaiting = true;
    context
        .read<BankSyncCubit>()
        .setMode(automatic ? ImportMode.automatic : ImportMode.review);
  }

  Future<void> _openShortcuts() async {
    final result = await UrlLauncherService.instance.launch('shortcuts://');
    if (!mounted) return;
    result.fold(
      (_) => showToast(
        context,
        message: 'bank_sync.shortcuts_unavailable'.tr(),
        status: 'info',
      ),
      (_) {},
    );
  }

  Future<void> _confirmDisconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('bank_sync.disconnect_title'.tr()),
        content: Text('bank_sync.disconnect_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('shared.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'bank_sync.disconnect'.tr(),
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _awaiting = _disconnecting = true);
    await context.read<BankSyncCubit>().disconnect();
  }

  void _onStateChanged(BuildContext context, BankSyncState state) {
    if (!_awaiting) return;
    switch (state.action) {
      case BankSyncAction.disconnected:
        setState(() => _awaiting = _disconnecting = false);
        showToast(context, message: 'bank_sync.disconnected'.tr());
      case BankSyncAction.linkUpdated:
        _awaiting = false;
      case BankSyncAction.failure:
        setState(() => _awaiting = _disconnecting = false);
        showToast(
          context,
          message: state.errorMessage ?? 'shared.something_wrong'.tr(),
          status: 'error',
        );
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return importListener(
      child: BlocConsumer<BankSyncCubit, BankSyncState>(
        listenWhen: (previous, current) => previous.action != current.action,
        listener: _onStateChanged,
        builder: (context, state) {
          return Scaffold(
            appBar: AppTopBar(title: 'bank_sync.title'.tr()),
            body: SafeArea(
              top: false,
              child: switch (state.status) {
                BankSyncStatus.initial ||
                BankSyncStatus.loading =>
                  const AppLoading(),
                BankSyncStatus.failure => AppErrorWidget(
                    message: state.errorMessage,
                    onRetry: () => context.read<BankSyncCubit>().load(),
                  ),
                BankSyncStatus.ready => state.isConnected
                    ? _connected(state)
                    : _notConnected(),
              },
            ),
          );
        },
      ),
    );
  }

  Widget _notConnected() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h),
            child: const LinkIntroSection(),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
          child: AppGradientButton(
            label: 'bank_sync.connect_cta'.tr(),
            onPressed: () => context.guardedPush(AppRoutes.bankLinkSetup),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Text(
            PlatformInfo.isIOS
                ? 'bank_sync.uses_shortcuts'.tr()
                : 'bank_sync.uses_sms'.tr(),
            textAlign: TextAlign.center,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
              fontSize: 11.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _connected(BankSyncState state) {
    final pending = state.pending.length;
    final lastMessageAt =
        state.messages.isEmpty ? null : state.messages.first.receivedAt;

    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
      children: [
        LinkStatusHero(
          link: state.link,
          pendingCount: pending,
          importedCount: state.imported.length,
          lastMessageAt: lastMessageAt,
          onTap: () => context.push(AppRoutes.bankInbox),
        ),
        SizedBox(height: 16.h),
        AppGradientButton(
          label: pending > 0
              ? 'bank_sync.review_count'.plural(pending)
              : 'bank_sync.open_inbox'.tr(),
          onPressed: () => context.push(AppRoutes.bankInbox),
        ),
        SizedBox(height: 24.h),
        SettingsSection(
          title: 'bank_sync.section_import'.tr(),
          rows: [
            _ToggleRow(
              title: 'bank_sync.auto_add_title'.tr(),
              description: 'bank_sync.auto_add_desc'.tr(),
              value: state.link.isAutomatic,
              onChanged: _setAutomatic,
            ),
            ProfileMenuRow(
              icon: Icons.content_paste_rounded,
              label: 'bank_sync.paste_title'.tr(),
              onTap: addPastedMessage,
            ),
          ],
        ),
        SizedBox(height: 20.h),
        SettingsSection(
          title: 'bank_sync.section_banks'.tr(),
          rows: [
            for (final bank in state.banks)
              BankRow(
                bank: bank,
                onTap: () => _toggleBank(state, bank.id),
                trailing: PillToggle(
                  value: state.link.bankIds.contains(bank.id),
                  onChanged: (_) => _toggleBank(state, bank.id),
                ),
              ),
          ],
        ),
        if (state.link.method == BankLinkMethod.shortcuts) ...[
          SizedBox(height: 20.h),
          SettingsSection(
            title: 'bank_sync.section_shortcut'.tr(),
            rows: [
              ProfileMenuRow(
                icon: Icons.bolt_rounded,
                label: 'bank_sync.open_shortcuts'.tr(),
                onTap: _openShortcuts,
              ),
              ProfileMenuRow(
                icon: Icons.menu_book_outlined,
                label: 'bank_sync.setup_guide'.tr(),
                onTap: () => context.push(AppRoutes.bankLinkSetup),
              ),
            ],
          ),
        ],
        SizedBox(height: 24.h),
        _DisconnectButton(
          isLoading: _disconnecting,
          onTap: _confirmDisconnect,
        ),
      ],
    );
  }
}

/// Soft-danger action: tinted red fill, red bold label.
class _DisconnectButton extends StatelessWidget {
  const _DisconnectButton({required this.onTap, this.isLoading = false});

  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 49.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.errorContainer,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: isLoading
            ? SizedBox(
                width: 18.r,
                height: 18.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.colors.error,
                ),
              )
            : Text(
                'bank_sync.disconnect'.tr(),
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.colors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 15.sp,
                ),
              ),
      ),
    );
  }
}

/// Title over supporting copy, with a [PillToggle] on the trailing edge.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 14.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: context.colors.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                      fontSize: 11.5.sp,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            PillToggle(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

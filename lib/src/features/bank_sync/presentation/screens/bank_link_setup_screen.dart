import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/bank_sync/domain/entities/bank.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_link.dart';
import 'package:mony_time/src/features/bank_sync/presentation/cubits/bank_sync_cubit.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/bank_avatar.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/bank_row.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/import_mode_option.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/instruction_step.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/note_banner.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/step_progress.dart';
import 'package:mony_time/src/features/setup/presentation/widgets/permission_row.dart';

/// Guided bank-SMS connection: choose banks → hook up the platform capture
/// (SMS access + an optional 30-day import on Android, a Shortcuts
/// automation on iPhone) → pick the import mode → connect once, at the end
/// → (Android) upload the last 30 days → done. Pops `true` once connected.
///
/// Refusing SMS access still connects: pasting messages keeps working.
class BankLinkSetupScreen extends StatefulWidget {
  const BankLinkSetupScreen({super.key, this.inFunnel = false});

  /// Opened from the post-signup welcome funnel: the done step only offers
  /// Continue (back to the funnel) instead of jumping into the inbox.
  final bool inFunnel;

  @override
  State<BankLinkSetupScreen> createState() => _BankLinkSetupScreenState();
}

enum _Phase { idle, connecting, scanning }

class _BankLinkSetupScreenState extends State<BankLinkSetupScreen> {
  static const _stepCount = 3;
  static const _doneStep = 3;

  late final BankLinkMethod _method;

  int _step = 0;
  final Set<String> _bankIds = {};
  ImportMode _mode = ImportMode.review;
  bool _scanHistory = true;

  /// Android SMS permission: granted, or asked and refused.
  bool _smsGranted = false;
  bool _smsDenied = false;
  bool _smsPermanentlyDenied = false;

  /// Connect, then (Android) the 30-day upload. Also guards the shared
  /// cubit's action stream.
  _Phase _phase = _Phase.idle;

  bool get _busy => _phase != _Phase.idle;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<BankSyncCubit>();
    _method = cubit.state.deviceMethod;
    // Re-running setup from the hub starts from the current choices.
    final link = cubit.state.link;
    _bankIds.addAll(link.bankIds);
    _mode = link.mode;
    if (cubit.state.banks.isEmpty) cubit.load();
    if (_method == BankLinkMethod.sms) _checkSmsPermission();
  }

  Future<void> _checkSmsPermission() async {
    final result = await PermissionService.instance.checkStatus(Permission.sms);
    if (!mounted) return;
    final granted = result.fold((_) => false, (s) => s.isGranted);
    if (granted) setState(() => _smsGranted = true);
  }

  /// RECEIVE_SMS (live capture) + READ_SMS (30-day import), asked here and
  /// only here.
  Future<void> _requestSms() async {
    final result = await PermissionService.instance.request(Permission.sms);
    if (!mounted) return;
    final status = result.fold((_) => PermissionStatus.denied, (s) => s);
    if (status.isGranted) {
      setState(() {
        _smsGranted = true;
        _smsDenied = false;
        _step++;
      });
      return;
    }
    setState(() {
      _smsDenied = true;
      _smsPermanentlyDenied = status.isPermanentlyDenied;
    });
  }

  bool get _isFirstOrDone => _step == 0 || _step == _doneStep;

  void _next() {
    if (_step == _stepCount - 1) {
      setState(() => _phase = _Phase.connecting);
      context.read<BankSyncCubit>().connect(
            bankIds: _bankIds.toList(),
            mode: _mode,
          );
      return;
    }
    setState(() => _step++);
  }

  void _back() {
    if (_isFirstOrDone) {
      _close();
    } else {
      setState(() => _step--);
    }
  }

  void _close() {
    final connected = context.read<BankSyncCubit>().state.isConnected;
    if (context.canPop()) {
      context.pop(connected);
    } else {
      context.go(AppRoutes.bankLink);
    }
  }

  void _toggleBank(String id) => setState(() {
        if (!_bankIds.remove(id)) _bankIds.add(id);
      });

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

  Future<void> _copySender(String sender) async {
    await Clipboard.setData(ClipboardData(text: sender));
    if (!mounted) return;
    showToast(
      context,
      message: 'bank_sync.copied'.tr(namedArgs: {'value': sender}),
    );
  }

  void _onStateChanged(BuildContext context, BankSyncState state) {
    if (!_busy) return;
    switch (state.action) {
      case BankSyncAction.connected:
        // The 30-day upload must follow connect: messages from banks that
        // aren't linked yet are rejected.
        if (_method == BankLinkMethod.sms && _smsGranted && _scanHistory) {
          setState(() => _phase = _Phase.scanning);
          context.read<BankSyncCubit>().scanHistory();
        } else {
          setState(() {
            _phase = _Phase.idle;
            _step = _doneStep;
          });
        }
      case BankSyncAction.scanned:
        setState(() {
          _phase = _Phase.idle;
          _step = _doneStep;
        });
      case BankSyncAction.failure:
        final wasScanning = _phase == _Phase.scanning;
        setState(() {
          _phase = _Phase.idle;
          // Connected already — only the history upload failed.
          if (wasScanning) _step = _doneStep;
        });
        showToast(
          context,
          message: wasScanning
              ? 'bank_sync.scan_failed'.tr()
              : state.errorMessage ?? 'shared.something_wrong'.tr(),
          status: wasScanning ? 'warning' : 'error',
        );
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BankSyncCubit, BankSyncState>(
      listenWhen: (previous, current) => previous.action != current.action,
      listener: _onStateChanged,
      builder: (context, state) {
        final connecting = _busy;

        return PopScope(
          canPop: _isFirstOrDone && !connecting,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !connecting) _back();
          },
          child: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  _Header(
                    isClose: _isFirstOrDone,
                    onTap: connecting ? null : _back,
                  ),
                  if (_step < _doneStep)
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'bank_sync.step_of'.tr(namedArgs: {
                              'current': '${_step + 1}',
                              'total': '$_stepCount',
                            }),
                            style: context.textTheme.labelSmall?.copyWith(
                              color: context.colors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.sp,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          StepProgress(count: _stepCount, current: _step),
                        ],
                      ),
                    ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: AppDurations.normal,
                      switchInCurve: AppCurves.pageEnter,
                      switchOutCurve: AppCurves.pageExit,
                      child: KeyedSubtree(
                        key: ValueKey(_step),
                        child: _body(state),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
                    child: _actions(state, connecting),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body(BankSyncState state) {
    return switch (_step) {
      0 => _StepScroll(
          title: 'bank_sync.banks_title'.tr(),
          subtitle: 'bank_sync.banks_subtitle'.tr(),
          children: [
            AppSoftCard(
              child: Column(
                children: [
                  for (var i = 0; i < state.banks.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: context.colors.outlineVariant,
                      ),
                    BankRow(
                      bank: state.banks[i],
                      onTap: () => _toggleBank(state.banks[i].id),
                      trailing: CheckDot(
                        selected: _bankIds.contains(state.banks[i].id),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 12.h),
            NoteBanner(
              icon: Icons.lock_outline_rounded,
              text: 'bank_sync.banks_note'.tr(),
            ),
          ],
        ),
      1 =>
        _method == BankLinkMethod.shortcuts ? _shortcutStep(state) : _smsStep(),
      2 => _StepScroll(
          title: 'bank_sync.mode_title'.tr(),
          subtitle: 'bank_sync.mode_subtitle'.tr(),
          children: [
            ImportModeOption(
              icon: Icons.fact_check_outlined,
              title: 'bank_sync.mode_review_title'.tr(),
              description: 'bank_sync.mode_review_desc'.tr(),
              badge: 'bank_sync.recommended'.tr(),
              selected: _mode == ImportMode.review,
              onTap: () => setState(() => _mode = ImportMode.review),
            ),
            SizedBox(height: 12.h),
            ImportModeOption(
              icon: Icons.bolt_rounded,
              title: 'bank_sync.mode_auto_title'.tr(),
              description: 'bank_sync.mode_auto_desc'.tr(),
              selected: _mode == ImportMode.automatic,
              onTap: () => setState(() => _mode = ImportMode.automatic),
            ),
            SizedBox(height: 14.h),
            NoteBanner(
              icon: Icons.tune_rounded,
              text: 'bank_sync.mode_note'.tr(),
            ),
          ],
        ),
      _ => _DoneView(
          banks: state.linkedBanks,
          pendingCount: state.summary.pendingCount,
        ),
    };
  }

  /// Shortcuts can't filter on the alphanumeric sender ids banks use (only
  /// on phone numbers), so the automation matches on a word every bank
  /// alert carries; the App Intent then keeps only the linked banks.
  static const _shortcutKeywords = ['جنيه', 'EGP', 'جم', 'ج.م'];

  Widget _shortcutStep(BankSyncState state) {
    return _StepScroll(
      title: 'bank_sync.shortcut_title'.tr(),
      subtitle: 'bank_sync.shortcut_subtitle'.tr(),
      children: [
        AppSoftCard(
          padding: EdgeInsets.all(16.r),
          child: Column(
            children: [
              InstructionStep(
                number: 1,
                title: 'bank_sync.shortcut_1_title'.tr(),
                description: 'bank_sync.shortcut_1_desc'.tr(),
              ),
              InstructionStep(
                number: 2,
                title: 'bank_sync.shortcut_2_title'.tr(),
                description: 'bank_sync.shortcut_2_desc'.tr(),
                child: Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: [
                    for (final keyword in _shortcutKeywords)
                      _CopyChip(
                        label: keyword,
                        onTap: () => _copySender(keyword),
                      ),
                  ],
                ),
              ),
              InstructionStep(
                number: 3,
                title: 'bank_sync.shortcut_3_title'.tr(),
                description: 'bank_sync.shortcut_3_desc'.tr(),
              ),
              InstructionStep(
                number: 4,
                title: 'bank_sync.shortcut_4_title'.tr(),
                description: 'bank_sync.shortcut_4_desc'.tr(),
                isLast: true,
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        AppButton(
          label: 'bank_sync.open_shortcuts'.tr(),
          variant: ButtonVariant.outline,
          isFullWidth: true,
          prefixIcon: Icon(Icons.open_in_new_rounded, size: 16.sp),
          onPressed: _openShortcuts,
        ),
      ],
    );
  }

  Widget _smsStep() {
    return _StepScroll(
      title: 'bank_sync.sms_title'.tr(),
      subtitle: 'bank_sync.sms_subtitle'.tr(
        namedArgs: {'count': '${_bankIds.length}'},
      ),
      children: [
        AppSoftCard(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ScopeHeading(text: 'bank_sync.sms_reads'.tr()),
              _ScopeRow(allowed: true, text: 'bank_sync.sms_reads_1'.tr()),
              _ScopeRow(allowed: true, text: 'bank_sync.sms_reads_2'.tr()),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: context.colors.outlineVariant,
                ),
              ),
              _ScopeHeading(text: 'bank_sync.sms_never'.tr()),
              _ScopeRow(allowed: false, text: 'bank_sync.sms_never_1'.tr()),
              _ScopeRow(allowed: false, text: 'bank_sync.sms_never_2'.tr()),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        AppSoftCard(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: PermissionRow(
            iconColor: context.colors.surface,
            emoji: '🗓️',
            title: 'bank_sync.scan_history_title'.tr(),
            description: 'bank_sync.scan_history_desc'.tr(),
            value: _scanHistory && !_smsDenied,
            onChanged: (v) {
              if (!_smsDenied) setState(() => _scanHistory = v);
            },
          ),
        ),
        if (_smsDenied) ...[
          SizedBox(height: 12.h),
          NoteBanner(
            icon: Icons.info_outline_rounded,
            tone: NoteTone.warning,
            title: 'bank_sync.sms_denied_title'.tr(),
            text: 'bank_sync.sms_denied_desc'.tr(),
          ),
        ],
      ],
    );
  }

  Widget _actions(BankSyncState state, bool connecting) {
    switch (_step) {
      case 0:
        return AppGradientButton(
          label: 'shared.continue_action'.tr(),
          onPressed: _bankIds.isEmpty ? null : _next,
        );
      case 1:
        if (_method == BankLinkMethod.shortcuts) {
          return AppGradientButton(
            label: 'bank_sync.shortcut_done'.tr(),
            onPressed: _next,
          );
        }
        if (_smsGranted) {
          return AppGradientButton(
            label: 'shared.continue_action'.tr(),
            onPressed: _next,
          );
        }
        if (!_smsDenied) {
          return AppGradientButton(
            label: 'bank_sync.allow_sms'.tr(),
            onPressed: _requestSms,
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppGradientButton(
              label: 'bank_sync.continue_without_sms'.tr(),
              onPressed: _next,
            ),
            SizedBox(height: 4.h),
            TextButton(
              onPressed: _smsPermanentlyDenied
                  ? () => PermissionService.instance.openSettings()
                  : _requestSms,
              child: Text(
                _smsPermanentlyDenied
                    ? 'bank_sync.open_settings'.tr()
                    : 'bank_sync.try_again'.tr(),
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5.sp,
                ),
              ),
            ),
          ],
        );
      case 2:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppGradientButton(
              label: 'bank_sync.finish'.tr(),
              isLoading: connecting,
              onPressed: _next,
            ),
            AnimatedSize(
              duration: AppDurations.fast,
              child: _phase == _Phase.idle
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: EdgeInsets.only(top: 10.h),
                      child: Text(
                        _phase == _Phase.scanning
                            ? 'bank_sync.scanning'.tr()
                            : 'bank_sync.connecting'.tr(),
                        textAlign: TextAlign.center,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                          fontSize: 11.5.sp,
                        ),
                      ),
                    ),
            ),
          ],
        );
    }

    final pending = state.summary.pendingCount;
    if (widget.inFunnel || pending == 0) {
      return AppGradientButton(
        label: widget.inFunnel
            ? 'shared.continue_action'.tr()
            : 'bank_sync.done'.tr(),
        onPressed: () => context.popOrGo(AppRoutes.bankLink),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppGradientButton(
          label: 'bank_sync.review_count'.plural(pending),
          onPressed: () => context.pushReplacement(AppRoutes.bankInbox),
        ),
        SizedBox(height: 4.h),
        TextButton(
          onPressed: () => context.popOrGo(AppRoutes.bankLink),
          child: Text(
            'bank_sync.later'.tr(),
            style: context.textTheme.labelMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              fontSize: 12.5.sp,
            ),
          ),
        ),
      ],
    );
  }
}

/// Close / back affordance with the flow title.
class _Header extends StatelessWidget {
  const _Header({required this.isClose, required this.onTap});

  final bool isClose;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onTap,
            icon: Icon(
              isClose ? Icons.close_rounded : Icons.arrow_back,
              size: 22.sp,
              color: context.colors.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              'bank_sync.setup_title'.tr(),
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ),
          SizedBox(width: 48.r),
        ],
      ),
    );
  }
}

/// A step's scrollable body: title, subtitle, then its content.
class _StepScroll extends StatelessWidget {
  const _StepScroll({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: context.textTheme.headlineSmall?.copyWith(
              color: context.colors.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 21.sp,
              height: 1.2,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            subtitle,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
              fontSize: 13.sp,
              height: 1.45,
            ),
          ),
          SizedBox(height: 18.h),
          ...children,
        ],
      ),
    );
  }
}

/// Tappable sender ID that copies itself (for the Shortcut's sender filter).
class _CopyChip extends StatelessWidget {
  const _CopyChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: AppBorders.full,
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(width: 6.w),
            Icon(
              Icons.copy_rounded,
              size: 13.sp,
              color: context.colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScopeHeading extends StatelessWidget {
  const _ScopeHeading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text.toUpperCase(),
        style: context.textTheme.labelSmall?.copyWith(
          color: context.colors.onSurfaceVariant,
          fontWeight: FontWeight.bold,
          fontSize: 10.5.sp,
        ),
      ),
    );
  }
}

/// ✓ / ✕ line in the SMS-access scope card.
class _ScopeRow extends StatelessWidget {
  const _ScopeRow({required this.allowed, required this.text});

  final bool allowed;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = allowed ? context.appColors.success : context.colors.error;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            allowed ? Icons.check_circle_rounded : Icons.block_rounded,
            size: 16.sp,
            color: color,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.onSurface,
                fontSize: 12.sp,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The success state after connecting: a check mark, the linked banks and
/// what was found.
class _DoneView extends StatelessWidget {
  const _DoneView({required this.banks, required this.pendingCount});

  final List<Bank> banks;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84.r,
              height: 84.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppGradients.primaryButton,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    offset: Offset(0, 12.h),
                    blurRadius: 24.r,
                    spreadRadius: -6.r,
                  ),
                ],
              ),
              child:
                  Icon(Icons.check_rounded, size: 40.sp, color: Colors.white),
            )
                .animate()
                .scale(
                  begin: const Offset(0.6, 0.6),
                  duration: AppDurations.medium,
                  curve: AppCurves.easeOutBack,
                )
                .fadeIn(duration: AppDurations.normal),
            SizedBox(height: 24.h),
            Text(
              'bank_sync.done_title'.tr(),
              textAlign: TextAlign.center,
              style: context.textTheme.headlineSmall?.copyWith(
                color: context.colors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 22.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              pendingCount > 0
                  ? 'bank_sync.done_found'.plural(pendingCount)
                  : 'bank_sync.done_waiting'.tr(),
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontSize: 13.sp,
                height: 1.45,
              ),
            ),
            SizedBox(height: 20.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              alignment: WrapAlignment.center,
              children: [
                for (final bank in banks) BankAvatar(bank: bank, size: 34.r),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/auth/presentation/helpers/auth_actions.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/presentation/cubits/bank_sync_cubit.dart';
import 'package:mony_time/src/features/bank_sync/presentation/helpers/bank_display.dart';
import 'package:mony_time/src/features/bank_sync/presentation/helpers/bank_import_flow.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/bank_avatar.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/edit_value_sheet.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/note_banner.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/sms_bubble.dart';
import 'package:mony_time/src/features/categories/presentation/models/category.dart';
import 'package:mony_time/src/features/transactions/presentation/widgets/detail_row.dart';

/// One bank message: the raw SMS, what we read out of it, and — while it is
/// pending — every field editable before Add. Settled messages show their
/// outcome (added / ignored, with Restore).
///
/// Watches [BankSyncCubit] by id so the status stays live.
class BankMessageScreen extends StatefulWidget {
  const BankMessageScreen({super.key, required this.message});

  final BankMessage message;

  @override
  State<BankMessageScreen> createState() => _BankMessageScreenState();
}

class _BankMessageScreenState extends State<BankMessageScreen>
    with BankImportFlow {
  // User edits; null = keep what was read from the SMS.
  TransactionType? _type;
  double? _amount;
  String? _merchant;
  AppCategory? _category;
  DateTime? _date;

  @override
  void onImported(int count) {
    showToast(context, message: 'bank_sync.added_count'.plural(count));
    context.popOrGo(AppRoutes.bankInbox);
  }

  Future<void> _editAmount(double current) async {
    final result = await showEditValueSheet(
      context,
      title: 'bank_sync.edit_amount'.tr(),
      initial: formatMoney(current).replaceAll(',', ''),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
    );
    final value = double.tryParse(result ?? '');
    if (value == null) return;
    if (value <= 0) {
      if (mounted) {
        showToast(
          context,
          message: 'transactions.invalid_amount'.tr(),
          status: 'error',
        );
      }
      return;
    }
    setState(() => _amount = value);
  }

  Future<void> _editMerchant(String current) async {
    final result = await showEditValueSheet(
      context,
      title: 'bank_sync.edit_merchant'.tr(),
      initial: current,
      hint: 'bank_sync.merchant_hint'.tr(),
    );
    if (result != null) setState(() => _merchant = result);
  }

  Future<void> _pickCategory(String currentLabel) async {
    final result = await context.push<AppCategory>(
      AppRoutes.categoryPicker,
      extra: currentLabel,
    );
    if (result != null) setState(() => _category = result);
  }

  Future<void> _pickDate(DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    // Keep the time of day the message carried.
    setState(() => _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          current.hour,
          current.minute,
        ));
  }

  void _add(BankMessage message, Bank? bank) {
    context.guardedRun(() => importMessages({
          message.id: message.toTransaction(
            bank,
            type: _type,
            amount: _amount,
            categoryEmoji: _category?.emoji,
            categoryLabel: _category?.label,
            date: _date,
            note: _merchant,
          ),
        }));
  }

  void _ignore(BankMessage message) {
    context.read<BankSyncCubit>().ignore(message.id);
    showToast(context, message: 'bank_sync.ignored_toast'.tr(), status: 'info');
    context.popOrGo(AppRoutes.bankInbox);
  }

  @override
  Widget build(BuildContext context) {
    return importListener(
      child: BlocBuilder<BankSyncCubit, BankSyncState>(
        builder: (context, state) {
          final message =
              state.messageById(widget.message.id) ?? widget.message;
          final bank = state.bankById(message.bankId);
          final locale = context.locale.toString();

          return Scaffold(
            appBar: AppTopBar(title: 'bank_sync.message_title'.tr()),
            body: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              BankAvatar(bank: bank, size: 34.r),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bank?.displayName(context) ??
                                          message.sender,
                                      style: context.textTheme.titleSmall
                                          ?.copyWith(
                                        color: context.colors.onSurface,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                    Text(
                                      'bank_sync.received'.tr(namedArgs: {
                                        'time': AppDate.relative(
                                            message.receivedAt, locale),
                                      }),
                                      style: context.textTheme.labelSmall
                                          ?.copyWith(
                                        color: context.colors.onSurfaceVariant,
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          SmsBubble(body: message.body),
                          SizedBox(height: 18.h),
                          ..._details(message, bank, locale),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
                    child: _actions(message, bank),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _details(BankMessage message, Bank? bank, String locale) {
    final p = message.parsed;
    if (p == null) {
      return [
        NoteBanner(
          icon: Icons.info_outline_rounded,
          title: 'bank_sync.not_transaction_short'.tr(),
          text: 'bank_sync.not_transaction_desc'.tr(),
        ),
      ];
    }

    final editable = message.status == BankMessageStatus.pending;
    final type = _type ?? p.type;
    final amount = _amount ?? p.amount;
    final merchant = _merchant ?? p.merchant ?? '';
    final emoji = _category?.emoji ?? p.categoryEmoji;
    final label = _category?.label ?? p.categoryLabel;
    final date = _date ?? message.occurredAt;
    final amountColor =
        type.isIncome ? context.colors.tertiary : context.colors.error;

    return [
      if (editable && !p.isConfident) ...[
        NoteBanner(
          icon: Icons.error_outline_rounded,
          tone: NoteTone.warning,
          title: !p.typeDetected && !p.currencyDetected
              ? 'bank_sync.check_both_title'.tr()
              : !p.typeDetected
                  ? 'bank_sync.check_type_title'.tr()
                  : 'bank_sync.check_amount_title'.tr(),
          text: [
            if (!p.typeDetected) 'bank_sync.check_type_desc'.tr(),
            if (!p.currencyDetected) 'bank_sync.check_amount_desc'.tr(),
          ].join(' '),
        ),
        SizedBox(height: 12.h),
      ],
      Text(
        'bank_sync.we_read'.tr().toUpperCase(),
        textAlign: TextAlign.center,
        style: context.textTheme.labelSmall?.copyWith(
          color: context.colors.onSurfaceVariant,
          fontWeight: FontWeight.bold,
          fontSize: 10.5.sp,
        ),
      ),
      SizedBox(height: 6.h),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          signedMoneyWithSymbol(amount, isIncome: type.isIncome),
textDirection: TextDirection.ltr,
maxLines: 1,
          style: context.textTheme.headlineMedium?.copyWith(
            color: amountColor,
            fontWeight: FontWeight.bold,
            fontSize: 30.sp,
            letterSpacing: -0.3,
          ),
        ),
      ),
      if (p.balance != null) ...[
        SizedBox(height: 2.h),
        Text(
          'bank_sync.balance_after'
              .tr(namedArgs: {'amount': moneyWithSymbol(p.balance!)}),
          textAlign: TextAlign.center,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
            fontSize: 11.sp,
          ),
        ),
      ],
      SizedBox(height: 16.h),
      if (editable) ...[
        TransactionTypeToggle(
          value: type,
          onChanged: (t) => setState(() => _type = t),
          style: SegmentedToggleStyle.soft,
          order: const [TransactionType.expense, TransactionType.income],
        ),
        SizedBox(height: 12.h),
      ],
      AppSoftCard(
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        child: Column(
          children: [
            DetailRow(
              label: 'bank_sync.amount'.tr(),
              value: moneyWithSymbol(amount),
              onTap: editable ? () => _editAmount(amount) : null,
            ),
            DetailRow(
              label: 'bank_sync.merchant'.tr(),
              value: merchant.isEmpty ? '—' : merchant,
              valueColor:
                  merchant.isEmpty ? context.colors.onSurfaceVariant : null,
              onTap: editable ? () => _editMerchant(merchant) : null,
            ),
            DetailRow(
              label: 'transactions.category'.tr(),
              value: '$emoji $label',
              onTap: editable ? () => _pickCategory(label) : null,
            ),
            DetailRow(
              label: 'transactions.date'.tr(),
              value: AppDate.fullDate(date, locale),
              onTap: editable ? () => _pickDate(date) : null,
            ),
            DetailRow(
              label: 'transactions.source'.tr(),
              value: message.accountLabel(bank),
              valueColor: context.colors.onSurfaceVariant,
              showDivider: false,
            ),
          ],
        ),
      ),
      if (editable) ...[
        SizedBox(height: 10.h),
        Text(
          'bank_sync.tap_to_edit'.tr(),
          textAlign: TextAlign.center,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
            fontSize: 11.sp,
          ),
        ),
      ],
    ];
  }

  Widget _actions(BankMessage message, Bank? bank) {
    switch (message.status) {
      case BankMessageStatus.pending:
        return Row(
          children: [
            Expanded(
              child: _SoftButton(
                label: 'bank_sync.ignore'.tr(),
                onTap: isImporting ? null : () => _ignore(message),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              flex: 2,
              child: AppGradientButton(
                label: 'bank_sync.add_transaction'.tr(),
                isLoading: isImporting,
                onPressed: () => _add(message, bank),
              ),
            ),
          ],
        );
      case BankMessageStatus.imported:
        return _StatusLine(
          icon: Icons.check_circle_rounded,
          color: context.appColors.success,
          text: 'bank_sync.already_added'.tr(),
        );
      case BankMessageStatus.ignored:
        if (!message.isTransaction) {
          return _StatusLine(
            icon: Icons.visibility_off_outlined,
            color: context.colors.onSurfaceVariant,
            text: 'bank_sync.filed_not_transaction'.tr(),
          );
        }
        return _SoftButton(
          label: 'bank_sync.restore_to_review'.tr(),
          accent: true,
          onTap: () => context.read<BankSyncCubit>().restore(message.id),
        );
    }
  }
}

/// Neutral 49-high action (Ignore), or brand-tinted when [accent].
class _SoftButton extends StatelessWidget {
  const _SoftButton({
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final fg = accent ? context.colors.primary : context.colors.onSurface;

    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 49.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent
                ? context.colors.primary.withValues(alpha: 0.1)
                : context.colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16.r),
            border: accent
                ? null
                : Border.all(color: context.colors.outlineVariant),
          ),
          child: Text(
            label,
            style: context.textTheme.titleSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.bold,
              fontSize: 15.sp,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 49.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18.sp, color: color),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              text,
              style: context.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13.5.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

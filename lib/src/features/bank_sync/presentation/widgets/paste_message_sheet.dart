import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/bank_sync/bank_sync_di.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/presentation/helpers/bank_display.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/bank_avatar.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/note_banner.dart';

typedef PastedMessage = ({String sender, String body});

/// "Add a bank message": pick the bank, paste the SMS, and see what we read
/// out of it before it goes to the inbox. Resolves to the message, or `null`
/// when dismissed.
Future<PastedMessage?> showPasteMessageSheet(
  BuildContext context, {
  required List<Bank> banks,
}) {
  return showModalBottomSheet<PastedMessage>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => _PasteMessageSheet(banks: banks),
  );
}

class _PasteMessageSheet extends StatefulWidget {
  const _PasteMessageSheet({required this.banks});

  final List<Bank> banks;

  @override
  State<_PasteMessageSheet> createState() => _PasteMessageSheetState();
}

class _PasteMessageSheetState extends State<_PasteMessageSheet> {
  final _controller = TextEditingController();
  late Bank? _bank = widget.banks.isEmpty ? null : widget.banks.first;
  ParsedBankSms? _preview;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    setState(() {
      _preview = BankSyncDi.parseMessage(text);
      _bank = _detectBank(text) ?? _bank;
    });
  }

  /// Most alerts name their bank — preselect it so the user rarely has to.
  Bank? _detectBank(String text) {
    final lower = text.toLowerCase();
    for (final bank in widget.banks) {
      if (lower.contains(bank.shortName.toLowerCase()) ||
          text.contains(bank.nameAr)) {
        return bank;
      }
    }
    return null;
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty || !mounted) return;
    _controller.text = text;
    _onChanged(text);
  }

  void _submit() {
    final bank = _bank;
    Navigator.of(context).pop((
      sender: bank?.senderIds.first ?? '',
      body: _controller.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        bottom: 16.h + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLowest,
          borderRadius: AppBorders.xxxl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'bank_sync.paste_title'.tr(),
                textAlign: TextAlign.center,
                style: context.textTheme.titleMedium?.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 17.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'bank_sync.paste_subtitle'.tr(),
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 16.h),
              if (widget.banks.isNotEmpty) ...[
                SizedBox(
                  height: 34.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.banks.length,
                    separatorBuilder: (_, __) => SizedBox(width: 8.w),
                    itemBuilder: (context, i) {
                      final bank = widget.banks[i];
                      return _BankChip(
                        bank: bank,
                        selected: bank.id == _bank?.id,
                        onTap: () => setState(() => _bank = bank),
                      );
                    },
                  ),
                ),
                SizedBox(height: 12.h),
              ],
              Container(
                height: 110.h,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  border: Border.all(color: context.colors.outlineVariant),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: TextField(
                  controller: _controller,
                  onChanged: _onChanged,
                  textDirection: hasText
                      ? smsDirection(_controller.text)
                      : Directionality.of(context),
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  cursorColor: context.colors.primary,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.onSurface,
                    fontSize: 12.5.sp,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: 'bank_sync.paste_hint'.tr(),
                    hintStyle: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                      fontSize: 12.5.sp,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: _paste,
                  icon: Icon(Icons.content_paste_rounded, size: 15.sp),
                  label: Text(
                    'bank_sync.paste_from_clipboard'.tr(),
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: AppDurations.fast,
                alignment: AlignmentDirectional.topCenter,
                child: !hasText
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: EdgeInsets.only(bottom: 14.h),
                        child: _preview == null
                            ? NoteBanner(
                                icon: Icons.info_outline_rounded,
                                tone: NoteTone.warning,
                                text: 'bank_sync.not_a_transaction'.tr(),
                              )
                            : _PreviewCard(parsed: _preview!),
                      ),
              ),
              AppGradientButton(
                label: 'bank_sync.add_to_inbox'.tr(),
                onPressed: hasText ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BankChip extends StatelessWidget {
  const _BankChip({
    required this.bank,
    required this.selected,
    required this.onTap,
  });

  final Bank bank;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: EdgeInsetsDirectional.fromSTEB(5.w, 5.h, 12.w, 5.h),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.08)
              : context.colors.surfaceContainerLowest,
          borderRadius: AppBorders.full,
          border: Border.all(
            color: selected ? primary : context.colors.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BankAvatar(bank: bank, size: 22.r),
            SizedBox(width: 6.w),
            Text(
              bank.shortName,
              style: context.textTheme.labelMedium?.copyWith(
                color: selected ? primary : context.colors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "We read: 🛒 Carrefour Maadi · −E£ 245.50".
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.parsed});

  final ParsedBankSms parsed;

  @override
  Widget build(BuildContext context) {
    final amountColor =
        parsed.type.isIncome ? context.colors.tertiary : context.colors.error;

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(parsed.categoryEmoji,
                style: TextStyle(fontSize: 15.sp)),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'bank_sync.we_read'.tr(),
                  style: context.textTheme.labelSmall?.copyWith(
                    color: parsed.isConfident
                        ? context.colors.primary
                        : context.appColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  parsed.merchant ?? parsed.categoryLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: context.colors.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            signedMoneyWithSymbol(
              parsed.amount,
              isIncome: parsed.type.isIncome,
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
            style: context.textTheme.titleSmall?.copyWith(
              color: amountColor,
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/bank_sync/domain/entities/bank.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/presentation/helpers/bank_display.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/bank_avatar.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/sms_bubble.dart';

/// A message waiting for review: who sent it and when, what we read out of it
/// (merchant, category, card, signed amount), a two-line preview of the raw
/// SMS, and quick Ignore / Add actions. A message that needs attention swaps
/// Add for Review so it can't be imported blind.
class BankMessageCard extends StatelessWidget {
  const BankMessageCard({
    super.key,
    required this.message,
    required this.bank,
    required this.onTap,
    required this.onAdd,
    required this.onIgnore,
    this.enabled = true,
  });

  final BankMessage message;
  final Bank? bank;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onIgnore;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Pending messages always carry parsed values (the server files the
    // rest as ignored); stay quiet rather than crash if one ever doesn't.
    final p = message.parsed;
    if (p == null) return const SizedBox.shrink();
    final locale = context.locale.toString();
    final attention = message.needsAttention;

    return AppSoftCard(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  BankAvatar(bank: bank, size: 30.r),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bank?.displayName(context) ?? message.sender,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.labelMedium?.copyWith(
                            color: context.colors.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5.sp,
                          ),
                        ),
                        Text(
                          [
                            if (p.cardLast4 != null) '•• ${p.cardLast4}',
                            AppDate.relative(message.receivedAt, locale),
                          ].join(' · '),
                          style: context.textTheme.labelSmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                            fontSize: 10.5.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (attention) const AttentionPill(),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.title(context, bank),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.titleSmall?.copyWith(
                            color: context.colors.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          message.categoryLine(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    message.signedAmount(),
                    textDirection: TextDirection.ltr,
                    maxLines: 1,
                    style: context.textTheme.titleMedium?.copyWith(
                      color: p.type.isIncome
                          ? context.colors.tertiary
                          : context.colors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      letterSpacing: -0.16,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              SmsBubble(body: message.body, maxLines: 2),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: CardActionButton(
                      label: 'bank_sync.ignore'.tr(),
                      icon: Icons.close_rounded,
                      onTap: enabled ? onIgnore : null,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: CardActionButton(
                      label: attention
                          ? 'bank_sync.review'.tr()
                          : 'bank_sync.add'.tr(),
                      icon:
                          attention ? Icons.edit_outlined : Icons.check_rounded,
                      filled: true,
                      onTap: enabled ? (attention ? onTap : onAdd) : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact 36-high action: a quiet neutral pill, or the brand gradient when
/// [filled].
class CardActionButton extends StatelessWidget {
  const CardActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : context.colors.onSurfaceVariant;

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 36.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? null : context.colors.surface,
            gradient: filled ? AppGradients.primaryButton : null,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15.sp, color: fg),
              SizedBox(width: 6.w),
              Text(
                label,
                style: context.textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

/// Amber "Check" tag on a message we couldn't read with certainty.
class AttentionPill extends StatelessWidget {
  const AttentionPill({super.key});

  @override
  Widget build(BuildContext context) {
    final warning = context.appColors.warning;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.12),
        borderRadius: AppBorders.full,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 12.sp, color: warning),
          SizedBox(width: 4.w),
          Text(
            'bank_sync.check'.tr(),
            style: context.textTheme.labelSmall?.copyWith(
              color: warning,
              fontWeight: FontWeight.bold,
              fontSize: 10.5.sp,
            ),
          ),
        ],
      ),
    );
  }
}

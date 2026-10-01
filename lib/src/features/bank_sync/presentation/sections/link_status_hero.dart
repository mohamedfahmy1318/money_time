import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/bank_sync/domain/entities/bank_link.dart';

/// Brand hero on the connected link hub: live status, how many messages wait,
/// when the last one arrived, and the review / added / banks counts.
class LinkStatusHero extends StatelessWidget {
  const LinkStatusHero({
    super.key,
    required this.link,
    required this.pendingCount,
    required this.importedCount,
    required this.lastMessageAt,
    this.onTap,
  });

  final BankLink link;
  final int pendingCount;
  final int importedCount;
  final DateTime? lastMessageAt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();
    final muted = Colors.white.withValues(alpha: 0.85);
    final last = lastMessageAt;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: AppGradients.hero,
          borderRadius: BorderRadius.circular(26.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.6),
              offset: Offset(0, 18.h),
              blurRadius: 30.r,
              spreadRadius: -14.r,
            ),
          ],
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              top: -30.r,
              end: -30.r,
              child: Container(
                width: 140.r,
                height: 140.r,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(18.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _LivePill(),
                      const Spacer(),
                      Text(
                        link.method == BankLinkMethod.shortcuts
                            ? 'bank_sync.via_shortcuts'.tr()
                            : 'bank_sync.via_sms'.tr(),
                        style: context.textTheme.labelSmall?.copyWith(
                          color: muted,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    pendingCount > 0
                        ? 'bank_sync.messages_to_review'.plural(pendingCount)
                        : 'bank_sync.all_caught_up'.tr(),
                    style: context.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    last == null
                        ? 'bank_sync.waiting_first'.tr()
                        : 'bank_sync.last_message'.tr(
                            namedArgs: {'time': AppDate.relative(last, locale)},
                          ),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: muted,
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: _GlassStat(
                          value: '$pendingCount',
                          label: 'bank_sync.stat_review'.tr(),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _GlassStat(
                          value: '$importedCount',
                          label: 'bank_sync.stat_added'.tr(),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _GlassStat(
                          value: '${link.bankIds.length}',
                          label: 'bank_sync.stat_banks'.tr(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: AppBorders.full,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7.r,
            height: 7.r,
            decoration: BoxDecoration(
              color: context.appColors.successContainer ?? Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            'profile.connected'.tr(),
            style: context.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassStat extends StatelessWidget {
  const _GlassStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: context.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
              height: 1.1,
            ),
          ),
          SizedBox(height: 2.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: context.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 10.5.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

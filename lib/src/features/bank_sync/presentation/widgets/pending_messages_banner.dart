import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/bank_sync/presentation/cubits/bank_sync_cubit.dart';

/// Home nudge shown while bank messages wait for review; collapses to nothing
/// otherwise. Carries its own top gap so it leaves no hole when hidden.
class PendingMessagesBanner extends StatelessWidget {
  const PendingMessagesBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.select<BankSyncCubit, int>(
      (c) => c.state.isConnected ? c.state.summary.pendingCount : 0,
    );
    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: AppSoftCard(
        child: InkWell(
          onTap: () => context.push(AppRoutes.bankInbox),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                Container(
                  width: 40.r,
                  height: 40.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryButton,
                    borderRadius: BorderRadius.circular(13.r),
                  ),
                  child:
                      Icon(Icons.sms_rounded, size: 19.sp, color: Colors.white),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'bank_sync.messages_to_review'.plural(count),
                        style: context.textTheme.titleSmall?.copyWith(
                          color: context.colors.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'bank_sync.banner_subtitle'.tr(),
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20.sp,
                  color: context.colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

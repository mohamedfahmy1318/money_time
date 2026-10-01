import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/bank_sync/presentation/helpers/bank_display.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/instruction_step.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/note_banner.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/sms_bubble.dart';

/// The pitch shown before a bank is linked: what the feature does, a worked
/// example (SMS in → transaction out), the three-step how-it-works, and the
/// privacy promise.
class LinkIntroSection extends StatelessWidget {
  const LinkIntroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 64.r,
            height: 64.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppGradients.primaryButton,
              borderRadius: BorderRadius.circular(21.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  offset: Offset(0, 10.h),
                  blurRadius: 20.r,
                  spreadRadius: -6.r,
                ),
              ],
            ),
            child: Icon(Icons.mark_chat_read_rounded,
                size: 28.sp, color: Colors.white),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'bank_sync.intro_title'.tr(),
          textAlign: TextAlign.center,
          style: context.textTheme.headlineSmall?.copyWith(
            color: context.colors.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 21.sp,
            height: 1.2,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'bank_sync.intro_subtitle'.tr(),
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
            fontSize: 13.sp,
            height: 1.45,
          ),
        ),
        SizedBox(height: 20.h),
        const _ExampleCard(),
        SizedBox(height: 20.h),
        AppSoftCard(
          padding: EdgeInsets.all(16.r),
          child: Column(
            children: [
              InstructionStep(
                number: 1,
                title: 'bank_sync.how_1_title'.tr(),
                description: 'bank_sync.how_1_desc'.tr(),
              ),
              InstructionStep(
                number: 2,
                title: 'bank_sync.how_2_title'.tr(),
                description: 'bank_sync.how_2_desc'.tr(),
              ),
              InstructionStep(
                number: 3,
                title: 'bank_sync.how_3_title'.tr(),
                description: 'bank_sync.how_3_desc'.tr(),
                isLast: true,
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        NoteBanner(
          icon: Icons.lock_outline_rounded,
          title: 'bank_sync.privacy_title'.tr(),
          text: 'bank_sync.privacy_desc'.tr(),
        ),
      ],
    );
  }
}

/// SMS bubble → arrow → the transaction row it becomes.
class _ExampleCard extends StatelessWidget {
  const _ExampleCard();

  @override
  Widget build(BuildContext context) {
    return AppSoftCard(
      padding: EdgeInsets.all(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'bank_sync.example_label'.tr().toUpperCase(),
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              fontSize: 10.5.sp,
            ),
          ),
          SizedBox(height: 8.h),
          const SmsBubble(
            body: 'Your CIB card ending 4821 was charged EGP 245.50 at '
                'CARREFOUR MAADI. Available limit EGP 12,450.00',
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Icon(
              Icons.arrow_downward_rounded,
              size: 18.sp,
              color: context.colors.primary,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: context.colors.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                Text('🛒', style: TextStyle(fontSize: 17.sp)),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Carrefour Maadi',
                        style: context.textTheme.titleSmall?.copyWith(
                          color: context.colors.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5.sp,
                        ),
                      ),
                      Text(
                        'Groceries · CIB •• 4821',
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
                Text(
                  signedMoneyWithSymbol(245.5, isIncome: false),
textDirection: TextDirection.ltr,
maxLines: 1,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: context.colors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/setup/presentation/models/app_currency.dart';

/// Gradient hero card previewing the chosen currency and symbol placement.
class CurrencyPreviewCard extends StatelessWidget {
  const CurrencyPreviewCard({
    super.key,
    required this.currency,
    required this.symbolPosition,
  });

  final AppCurrency currency;
  final SymbolPosition symbolPosition;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100.h,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryMid, AppColors.primaryDeep],
          stops: [0.0, 0.7, 1.0],
        ),
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
          Positioned(
            top: -30.r,
            right: -30.r,
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
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'setup.selected'.tr(),
                  style: context.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
                Text(
                  currency.previewAmount(symbolPosition),
                  style: context.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 25.5.sp,
                    letterSpacing: -0.52,
                  ),
                ),
                Text(
                  '${currency.code} — ${currency.name}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.sp,
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

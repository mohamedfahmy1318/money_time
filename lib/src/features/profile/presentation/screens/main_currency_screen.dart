import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/profile/presentation/widgets/info_field_row.dart';

/// Main Currency: the detected currency and rate over unit/decimal preferences,
/// with a Save action. Display-only for the UI phase.
class MainCurrencyScreen extends StatelessWidget {
  const MainCurrencyScreen({super.key});

  void _comingSoon(BuildContext context) =>
      showToast(context, message: 'profile.coming_soon'.tr(), status: 'info');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'settings.main_currency'.tr(),
        actions: [
          TextButton(
            onPressed: () => _comingSoon(context),
            child: Text(
              'main_currency.change'.tr(),
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Hero(),
                    InfoFieldRow(
                      label: 'main_currency.unit_position'.tr(),
                      value: 'main_currency.unit_front'.tr(),
                    ),
                    InfoFieldRow(
                      label: 'main_currency.decimal_point'.tr(),
                      value: '1.00',
                    ),
                    SizedBox(height: 16.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _AutoDetectPill(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
              child: AppGradientButton(
                label: 'main_currency.save'.tr(),
                onPressed: () => context.pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 14.h),
        Text(
          r'USD — United States ($)',
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
            fontSize: 13.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          r'$ 1.00',
          textAlign: TextAlign.center,
          style: context.textTheme.headlineMedium?.copyWith(
            color: context.colors.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 29.3.sp,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Divider(
            height: 1,
            thickness: 1,
            color: context.colors.outlineVariant,
          ),
        ),
      ],
    );
  }
}

class _AutoDetectPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: AppBorders.full,
      ),
      child: Text(
        'main_currency.auto_detected'.tr(),
        style: context.textTheme.labelSmall?.copyWith(
          color: context.colors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 11.sp,
        ),
      ),
    );
  }
}

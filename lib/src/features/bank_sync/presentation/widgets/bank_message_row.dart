import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/bank_sync/domain/entities/bank.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/presentation/helpers/bank_display.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/bank_avatar.dart';

/// A settled message (added or ignored) in a list card: bank monogram, title
/// over [subtitle], and the signed amount — or a custom [trailing] action.
class BankMessageRow extends StatelessWidget {
  const BankMessageRow({
    super.key,
    required this.message,
    required this.bank,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final BankMessage message;
  final Bank? bank;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = message.parsed;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          children: [
            BankAvatar(bank: bank, size: 36.r),
            SizedBox(width: 12.w),
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
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
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
            SizedBox(width: 12.w),
            trailing ??
                Text(
                  message.signedAmount(),
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: p == null
                        ? context.colors.onSurfaceVariant
                        : p.type.isIncome
                            ? context.colors.tertiary
                            : context.colors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.7.sp,
                    letterSpacing: -0.14,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

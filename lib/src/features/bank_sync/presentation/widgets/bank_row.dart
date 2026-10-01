import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/bank_sync/domain/entities/bank.dart';
import 'package:mony_time/src/features/bank_sync/presentation/helpers/bank_display.dart';
import 'package:mony_time/src/features/bank_sync/presentation/widgets/bank_avatar.dart';

/// A bank in a list: monogram, localised name over the SMS sender it reads,
/// and a [trailing] control (a [CheckDot] when picking, a toggle in settings).
class BankRow extends StatelessWidget {
  const BankRow({
    super.key,
    required this.bank,
    required this.trailing,
    this.onTap,
  });

  final Bank bank;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 11.h),
        child: Row(
          children: [
            BankAvatar(bank: bank, size: 36.r),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bank.displayName(context),
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
                    'bank_sync.sender_label'
                        .tr(namedArgs: {'sender': bank.senderIds.first}),
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// Round selection mark: filled with a check when [selected].
class CheckDot extends StatelessWidget {
  const CheckDot({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.fast,
      width: 22.r,
      height: 22.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? context.colors.primary : Colors.transparent,
        border: Border.all(
          color: selected ? context.colors.primary : context.colors.outlineVariant,
          width: 1.5,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: 14.r, color: Colors.white)
          : null,
    );
  }
}

import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/transactions/presentation/widgets/detail_row.dart';

/// The date / amount / category rows plus the note affordance shown between the
/// type toggle and the keypad.
class TransactionDetails extends StatelessWidget {
  const TransactionDetails({
    super.key,
    required this.date,
    required this.amount,
    required this.category,
    required this.hasNote,
    required this.onTapDate,
    required this.onTapCategory,
    required this.onAddNote,
  });

  final String date;
  final String amount;
  final String category;
  final bool hasNote;
  final VoidCallback onTapDate;
  final VoidCallback onTapCategory;
  final VoidCallback onAddNote;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DetailRow(
          label: 'transactions.date'.tr(),
          value: date,
          onTap: onTapDate,
        ),
        DetailRow(
          label: 'transactions.amount'.tr(),
          value: amount,
        ),
        DetailRow(
          label: 'transactions.category'.tr(),
          value: category,
          onTap: onTapCategory,
        ),
        SizedBox(height: 18.h),
        Row(
          children: [
            Text(
              'transactions.note'.tr(),
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
            const Spacer(),
            _NoteButton(active: hasNote, onTap: onAddNote),
          ],
        ),
      ],
    );
  }
}

/// The small square note button on the trailing edge of the note row.
class _NoteButton extends StatelessWidget {
  const _NoteButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38.r,
        height: 38.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLowest,
          border: Border.all(color: context.colors.outlineVariant),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(
          Icons.edit_note_rounded,
          size: 20.sp,
          color: active ? context.colors.primary : context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

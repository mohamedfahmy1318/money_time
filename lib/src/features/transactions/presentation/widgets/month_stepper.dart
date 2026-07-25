import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// Centered `‹  label  ›` period stepper (month or year) used across the
/// ledger views.
class MonthStepper extends StatelessWidget {
  const MonthStepper({
    super.key,
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Chevron(glyph: '‹', onTap: onPrev),
        SizedBox(width: 6.w),
        Text(
          label,
          style: context.textTheme.titleSmall?.copyWith(
            color: context.colors.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(width: 6.w),
        _Chevron(glyph: '›', onTap: onNext),
      ],
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({required this.glyph, required this.onTap});

  final String glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // Generous hit target around the small glyph.
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        child: Text(
          glyph,
          style: context.textTheme.titleSmall?.copyWith(
            color: context.colors.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }
}

import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// A full-width settings row: a dark [label] on the leading edge and a coloured
/// [value] (primary by default) on the trailing edge, optionally followed by a
/// chevron. A hairline divider closes the row unless [showDivider] is false.
class SettingValueRow extends StatelessWidget {
  const SettingValueRow({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
    this.showChevron = false,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 47.h,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: context.textTheme.titleSmall?.copyWith(
                        color: context.colors.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    value,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5.sp,
                    ),
                  ),
                  if (showChevron) ...[
                    SizedBox(width: 2.w),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16.sp,
                      color: context.colors.primary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
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

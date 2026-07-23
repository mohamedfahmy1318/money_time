import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// A single tappable row in a picker list: leading glyph, label, and an
/// optional trailing hint. When [selected], the row fills with the tonal
/// primary tint and shows a check.
class SelectableOptionTile extends StatelessWidget {
  const SelectableOptionTile({
    super.key,
    required this.leading,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  /// Usually a flag/emoji rendered as text.
  final String leading;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Small hint on the trailing side (e.g. the auto-detected code).
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final selectedInk = context.colors.onPrimaryContainer;

    return Material(
      color: selected ? context.colors.primaryContainer : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
          child: Row(
            children: [
              Text(leading, style: TextStyle(fontSize: 15.sp)),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  label,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: selected ? selectedInk : context.colors.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5.sp,
                  ),
                ),
              ),
              if (trailing != null) ...[
                Text(
                  trailing!,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: selected
                        ? selectedInk
                        : context.colors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(width: 8.w),
              ],
              if (selected)
                Icon(Icons.check_rounded, color: selectedInk, size: 16.r),
            ],
          ),
        ),
      ),
    );
  }
}

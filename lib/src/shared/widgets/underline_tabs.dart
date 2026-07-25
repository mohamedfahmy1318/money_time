import '../../imports/core_imports.dart';
import '../../imports/packages_imports.dart';

/// Text tabs with a 2px coloured underline beneath the active one — the
/// Figma "underline indicator" tab style used by the transactions hub, the
/// filter screen and the reports Note view.
///
/// By default the active tab tints brand primary; pass [colors] to give each
/// tab its own accent (e.g. income blue / expense red).
class UnderlineTabs extends StatelessWidget {
  const UnderlineTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.colors,
  }) : assert(colors == null || colors.length == labels.length,
            'one colour per label');

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// Optional per-tab accent for the active label + underline.
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: _Tab(
              label: labels[i],
              selected: i == selectedIndex,
              accent: colors?[i] ?? context.colors.primary,
              onTap: () => onChanged(i),
            ),
          ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelLarge?.copyWith(
              color: selected ? accent : context.colors.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              fontSize: 12.5.sp,
            ),
          ),
          SizedBox(height: 10.h),
          AnimatedContainer(
            duration: AppDurations.quick,
            curve: AppCurves.standard,
            height: 2.h,
            color: selected ? accent : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

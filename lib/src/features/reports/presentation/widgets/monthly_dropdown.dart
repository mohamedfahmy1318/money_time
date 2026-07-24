import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// The small emerald "Monthly ▾" period picker shown in the reports headers.
/// Self-contained — keeps its own selection so callers stay simple.
class MonthlyDropdown extends StatefulWidget {
  const MonthlyDropdown({super.key});

  @override
  State<MonthlyDropdown> createState() => _MonthlyDropdownState();
}

class _MonthlyDropdownState extends State<MonthlyDropdown> {
  static const _options = ['reports.weekly', 'reports.monthly', 'reports.annually'];
  String _value = 'reports.monthly';

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      onSelected: (v) => setState(() => _value = v),
      itemBuilder: (_) => [
        for (final key in _options)
          PopupMenuItem<String>(value: key, child: Text(key.tr())),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _value.tr(),
            style: context.textTheme.labelMedium?.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded, color: context.colors.primary, size: 16.sp),
        ],
      ),
    );
  }
}

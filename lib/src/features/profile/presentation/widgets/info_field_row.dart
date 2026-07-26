import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// A row in the personal-info card: a muted label on the leading edge and a
/// right-aligned value on the trailing edge. The value is an inline borderless
/// [TextField] when a [controller] is given, a custom [trailing] widget when
/// provided, or static [value] text otherwise. A hairline divider closes the
/// row unless [showDivider] is false (the last row).
class InfoFieldRow extends StatelessWidget {
  const InfoFieldRow({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.value,
    this.valueColor,
    this.trailing,
    this.keyboardType,
    this.showDivider = true,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? value;
  final Color? valueColor;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final valueStyle = context.textTheme.titleSmall?.copyWith(
      color: valueColor ?? context.colors.onSurface,
      fontWeight: FontWeight.bold,
      fontSize: 14.5.sp,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 47.h,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 19.w),
            child: Row(
              children: [
                Text(
                  label,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(child: _buildValue(context, valueStyle)),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            child: Divider(
              height: 1,
              thickness: 1,
              color: context.colors.outlineVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildValue(BuildContext context, TextStyle? valueStyle) {
    if (trailing != null) {
      return Align(alignment: AlignmentDirectional.centerEnd, child: trailing);
    }
    if (controller != null) {
      return TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: TextAlign.end,
        style: valueStyle,
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: valueStyle?.copyWith(
            color: context.colors.onSurfaceVariant,
            fontWeight: FontWeight.normal,
          ),
        ),
      );
    }
    return Text(value ?? '', textAlign: TextAlign.end, style: valueStyle);
  }
}

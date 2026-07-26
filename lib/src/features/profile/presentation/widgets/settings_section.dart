import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// A settings group: a muted uppercase [title] over an [AppSoftCard] whose
/// [rows] are separated by hairline dividers.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.rows,
  });

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 10.h),
          child: Text(
            title.toUpperCase(),
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              fontSize: 11.5.sp,
              letterSpacing: 0.575,
            ),
          ),
        ),
        AppSoftCard(
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: context.colors.outlineVariant,
                  ),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

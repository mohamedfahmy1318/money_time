import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// Hairline "── or ──" separator between the primary action and social sign-in.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Divider(color: context.colors.outlineVariant, height: 1),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            'auth.or'.tr(),
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colors.outline,
              fontSize: 11.sp,
            ),
          ),
        ),
        line,
      ],
    );
  }
}

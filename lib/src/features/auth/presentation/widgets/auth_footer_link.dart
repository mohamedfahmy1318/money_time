import 'package:mony_time/src/imports/core_imports.dart';

/// "Don't have an account? **Sign Up**" style footer link.
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text.rich(
        TextSpan(
          text: prompt,
          style: context.textTheme.bodyMedium
              ?.copyWith(color: context.colors.onSurfaceVariant),
          children: [
            TextSpan(
              text: action,
              style: TextStyle(
                color: context.colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

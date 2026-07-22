import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/auth/presentation/widgets/social_icon_button.dart';

/// "Or continue with" label + social provider buttons.
class SocialLoginSection extends StatelessWidget {
  const SocialLoginSection({
    super.key,
    this.onGoogle,
    this.onFacebook,
    this.onApple,
  });

  final VoidCallback? onGoogle;
  final VoidCallback? onFacebook;
  final VoidCallback? onApple;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'auth.or_continue_with'.tr(),
          style: context.textTheme.bodySmall
              ?.copyWith(color: context.colors.onSurfaceVariant),
        ),
        SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 20.w,
          children: [
            SocialIconButton(
              asset: AppAssets.googleIcon,
              backgroundColor: const Color(0xFFEA4335).withValues(alpha: 0.8),
              onPressed: onGoogle,
            ),
            SocialIconButton(
              asset: AppAssets.facebookIcon,
              backgroundColor: const Color(0xFF4285F4),
              onPressed: onFacebook,
            ),
            SocialIconButton(
              asset: AppAssets.appleIcon,
              backgroundColor: const Color(0xFF000000),
              onPressed: onApple,
            ),
          ],
        ),
      ],
    );
  }
}

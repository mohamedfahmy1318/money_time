import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// Square social-provider button (Google / Facebook / Apple).
class SocialIconButton extends StatelessWidget {
  const SocialIconButton({
    super.key,
    required this.asset,
    required this.backgroundColor,
    this.onPressed,
  });

  final String asset;
  final Color backgroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50.w,
      height: 50.w,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          shape: const RoundedRectangleBorder(borderRadius: AppBorders.button),
        ),
        child: SvgPicture.asset(asset),
      ),
    );
  }
}

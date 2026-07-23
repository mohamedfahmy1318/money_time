import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// Rounded translucent tile holding the Money Time mark.
class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104.r,
      height: 104.r,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(32.r),
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        AppAssets.logo,
        width: 60.r,
        height: 60.r,
      ),
    );
  }
}

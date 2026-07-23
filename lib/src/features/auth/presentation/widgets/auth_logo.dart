import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// Dark rounded tile holding the Money Time clock mark — the crest at the top
/// of the login screen.
class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56.r,
      height: 56.r,
      decoration: BoxDecoration(
        color: context.colors.onSurface,
        borderRadius: BorderRadius.circular(17.r),
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        AppAssets.logoMarkDark,
        width: 32.r,
        height: 32.r,
      ),
    );
  }
}

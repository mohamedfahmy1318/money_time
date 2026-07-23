import '../../imports/imports.dart';

/// A wrapper to initialize [ScreenUtil] with design-specific constraints.
///
/// [designSize] is the Figma artboard's inner screen area (298×672 — the
/// device-mockup frame minus its 11 px bezel). Keeping the baseline identical
/// to the artboard means every value copied out of Figma maps 1:1 onto
/// `.w` / `.h` / `.r` / `.sp` with no manual conversion.
class ScreenUtilWrapper extends StatelessWidget {
  final Widget child;
  final Size designSize;
  final bool minTextAdapt;
  final bool splitScreenMode;

  const ScreenUtilWrapper({
    super.key,
    required this.child,
    this.designSize = const Size(298, 672),
    this.minTextAdapt = true,
    this.splitScreenMode = true,
  });

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: designSize,
      minTextAdapt: minTextAdapt,
      splitScreenMode: splitScreenMode,
      builder: (context, _) => child,
    );
  }
}

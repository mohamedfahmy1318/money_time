import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// White rounded container with the hairline border and soft shadow shared by
/// every setup surface (language list, currency list, permission card).
class SetupCard extends StatelessWidget {
  const SetupCard({
    super.key,
    required this.child,
    this.clip = false,
  });

  final Widget child;

  /// Clip children to the rounded corners — needed when a child paints an
  /// edge-to-edge fill (e.g. the selected row tint).
  final bool clip;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: AppBorders.xl,
        border: Border.all(color: context.colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: context.colors.onSurface.withValues(alpha: 0.05),
            offset: Offset(0, 4.h),
            blurRadius: 14.r,
          ),
        ],
      ),
      child: child,
    );
  }
}

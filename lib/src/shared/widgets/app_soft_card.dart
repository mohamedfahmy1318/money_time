import '../../imports/core_imports.dart';
import '../../imports/packages_imports.dart';

/// A white, radius-20 surface with a hairline border and the soft Figma drop
/// shadow — the card style shared by the reports and profile features. Children
/// manage their own padding (list cards go edge-to-edge for full-width
/// dividers).
class AppSoftCard extends StatelessWidget {
  const AppSoftCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// The card look on its own — for lazy lists that paint it behind a
  /// sliver instead of wrapping every row in a card.
  static BoxDecoration decorationOf(BuildContext context) => BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: context.colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            offset: Offset(0, 4.h),
            blurRadius: 7.r,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: decorationOf(context),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
  }
}

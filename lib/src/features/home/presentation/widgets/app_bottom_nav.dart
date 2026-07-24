import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// One destination in the bottom navigation bar.
class BottomNavItem {
  const BottomNavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// Custom bottom navigation bar with a raised gradient "add" FAB in the
/// centre. Four tab destinations flank the FAB (two on each side).
///
/// Rendered inside a `Stack` in the body (not the Scaffold's
/// `bottomNavigationBar` slot) so the FAB can rise above the bar without
/// being clipped.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.onAdd,
  });

  final List<BottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    assert(items.length == 4, 'AppBottomNav expects exactly 4 destinations');
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: 73.h + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 57.h + bottomInset,
              padding: EdgeInsets.only(bottom: bottomInset),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerLowest,
                border: Border(
                  top: BorderSide(color: context.colors.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: _NavButton(item: items[0], selected: currentIndex == 0, onTap: () => onTap(0))),
                  Expanded(child: _NavButton(item: items[1], selected: currentIndex == 1, onTap: () => onTap(1))),
                  SizedBox(width: 66.w),
                  Expanded(child: _NavButton(item: items[2], selected: currentIndex == 2, onTap: () => onTap(2))),
                  Expanded(child: _NavButton(item: items[3], selected: currentIndex == 3, onTap: () => onTap(3))),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 16.h + bottomInset,
            child: Center(child: _AddFab(onTap: onAdd)),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final BottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? context.colors.primary : context.colors.onSurfaceVariant;
    return InkResponse(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, color: color, size: 20.sp),
          SizedBox(height: 3.h),
          Text(
            item.label,
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddFab extends StatelessWidget {
  const _AddFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56.r,
        height: 56.r,
        decoration: BoxDecoration(
          gradient: AppGradients.primaryButton,
          borderRadius: BorderRadius.circular(19.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.7),
              offset: Offset(0, 12.h),
              blurRadius: 22.r,
              spreadRadius: -6.r,
            ),
          ],
        ),
        child: Icon(Icons.add_rounded, color: Colors.white, size: 26.sp),
      ),
    );
  }
}

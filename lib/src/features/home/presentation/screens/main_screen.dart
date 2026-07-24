import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/home/presentation/screens/home_tab.dart';
import 'package:mony_time/src/features/home/presentation/widgets/app_bottom_nav.dart';

/// Authenticated shell hosting the four bottom-nav tabs and the central add
/// action. Tabs are kept alive via an [IndexedStack]; only Home is designed so
/// far — the rest are placeholders.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  static final _tabs = <Widget>[
    const HomeTab(),
    const _PlaceholderTab(titleKey: 'home.nav_budget'),
    const _PlaceholderTab(titleKey: 'home.nav_reports'),
    const _PlaceholderTab(titleKey: 'home.nav_profile'),
  ];

  List<BottomNavItem> _items() => [
        BottomNavItem(icon: Icons.home_outlined, label: 'home.nav_home'.tr()),
        BottomNavItem(icon: Icons.schedule_rounded, label: 'home.nav_budget'.tr()),
        BottomNavItem(icon: Icons.bar_chart_rounded, label: 'home.nav_reports'.tr()),
        BottomNavItem(icon: Icons.person_outline_rounded, label: 'home.nav_profile'.tr()),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(index: _index, children: _tabs),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomNav(
              items: _items(),
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
              onAdd: () => context.push(AppRoutes.addTransaction),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.titleKey});

  final String titleKey;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.construction_rounded,
              size: 40.sp,
              color: context.colors.onSurfaceVariant,
            ),
            SizedBox(height: 12.h),
            Text(
              titleKey.tr(),
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'home.coming_soon'.tr(),
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

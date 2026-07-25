import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/home/presentation/screens/home_tab.dart';
import 'package:mony_time/src/features/home/presentation/widgets/app_bottom_nav.dart';

/// Authenticated shell hosting the four bottom-nav tabs and the central add
/// action: Home · Budget · Reports · Profile. The transactions ledger is a
/// pushed route (Home → "See all"). Tabs are kept alive via an [IndexedStack].
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  static const _tabs = <Widget>[
    HomeTab(),
    BudgetTab(),
    ReportsTab(),
    ProfileTab(),
  ];

  List<BottomNavItem> _items() => [
        BottomNavItem(icon: Icons.home_outlined, label: 'home.nav_home'.tr()),
        BottomNavItem(
          icon: Icons.pie_chart_outline_rounded,
          label: 'home.nav_budget'.tr(),
        ),
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

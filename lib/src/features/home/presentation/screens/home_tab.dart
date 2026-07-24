import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/home/presentation/models/home_data.dart';
import 'package:mony_time/src/features/home/presentation/sections/budget_card.dart';
import 'package:mony_time/src/features/home/presentation/sections/categories_section.dart';
import 'package:mony_time/src/features/home/presentation/sections/home_header.dart';
import 'package:mony_time/src/features/home/presentation/sections/recent_section.dart';

/// The Home dashboard tab: greeting header over a scrolling budget summary,
/// categories and recent activity. Content is [HomeSampleData] for the UI
/// phase.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const HomeHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 2.h, 20.w, 100.h),
              child: Column(
                children: [
                  const BudgetCard(budget: HomeSampleData.budget),
                  SizedBox(height: 24.h),
                  const CategoriesSection(
                    categories: HomeSampleData.categories,
                  ),
                  SizedBox(height: 24.h),
                  const RecentSection(
                    transactions: HomeSampleData.recent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

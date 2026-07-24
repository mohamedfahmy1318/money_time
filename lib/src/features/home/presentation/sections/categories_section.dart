import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/home/presentation/models/home_data.dart';
import 'package:mony_time/src/features/home/presentation/widgets/category_chip.dart';
import 'package:mony_time/src/features/home/presentation/widgets/section_header.dart';

/// "Categories" header plus a row of category chips ending in an add tile.
class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key, required this.categories});

  final List<HomeCategory> categories;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(
          title: 'home.categories'.tr(),
          action: 'home.manage'.tr(),
          onAction: () {},
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            for (final category in categories) ...[
              Expanded(
                child: CategoryChip(
                  emoji: category.emoji,
                  label: category.label,
                  tint: category.tint,
                  onTap: () {},
                ),
              ),
              SizedBox(width: 10.w),
            ],
            Expanded(
              child: CategoryChip.add(
                label: 'home.add'.tr(),
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}

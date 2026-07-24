import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/categories/presentation/models/category.dart';
import 'package:mony_time/src/features/categories/presentation/widgets/category_pick_tile.dart';

/// Full-screen category chooser. Tapping a tile pops with the chosen [Category];
/// the dashed "Add" tile opens the add-category screen.
class CategoryPickerScreen extends StatefulWidget {
  const CategoryPickerScreen({super.key, this.selectedLabel});

  /// Label of the category to pre-highlight (e.g. the one already on the form).
  final String? selectedLabel;

  @override
  State<CategoryPickerScreen> createState() => _CategoryPickerScreenState();
}

class _CategoryPickerScreenState extends State<CategoryPickerScreen> {
  TransactionType _type = TransactionType.expense;
  late final String _selectedLabel =
      widget.selectedLabel ?? CategorySampleData.categories.first.label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'categories.picker_title'.tr()),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 2.h),
              TransactionTypeToggle(
                value: _type,
                onChanged: (t) => setState(() => _type = t),
                style: SegmentedToggleStyle.soft,
                order: const [TransactionType.expense, TransactionType.income],
              ),
              SizedBox(height: 22.h),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 14.w,
                    runSpacing: 18.h,
                    children: [
                      for (final category in CategorySampleData.categories)
                        CategoryPickTile(
                          emoji: category.emoji,
                          label: category.label,
                          selected: category.label == _selectedLabel,
                          onTap: () => context.pop(category),
                        ),
                      CategoryPickTile.add(
                        label: 'categories.add'.tr(),
                        onTap: () => context.push(AppRoutes.addCategory),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

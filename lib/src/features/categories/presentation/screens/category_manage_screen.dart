import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/categories/presentation/models/category.dart';
import 'package:mony_time/src/features/categories/presentation/widgets/category_manage_row.dart';
import 'package:mony_time/src/features/setup/presentation/widgets/pill_toggle.dart';

/// Manage the income or expense category list: toggle subcategories, delete a
/// category, or add a new one. Seeded from sample data for the UI phase —
/// deletions are local and edits surface a "coming soon" toast.
class CategoryManageScreen extends StatefulWidget {
  const CategoryManageScreen({super.key, required this.type});

  final TransactionType type;

  @override
  State<CategoryManageScreen> createState() => _CategoryManageScreenState();
}

class _CategoryManageScreenState extends State<CategoryManageScreen> {
  late final List<AppCategory> _items = List.of(
    widget.type == TransactionType.income
        ? CategorySampleData.incomeCategories
        : CategorySampleData.categories,
  );
  bool _subcategory = false;

  void _comingSoon() =>
      showToast(context, message: 'profile.coming_soon'.tr(), status: 'info');

  @override
  Widget build(BuildContext context) {
    final title = widget.type == TransactionType.income
        ? 'settings.income_categories'.tr()
        : 'settings.expense_categories'.tr();

    return Scaffold(
      appBar: AppTopBar(
        title: title,
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.addCategory),
            icon: Icon(Icons.add_rounded, size: 24.sp),
            color: context.colors.onSurface,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SubcategoryRow(
              value: _subcategory,
              onChanged: (v) => setState(() => _subcategory = v),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.only(bottom: 24.h),
                itemCount: _items.length,
                separatorBuilder: (_, __) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: context.colors.outlineVariant,
                  ),
                ),
                itemBuilder: (context, index) => CategoryManageRow(
                  emoji: _items[index].emoji,
                  label: _items[index].label,
                  onDelete: () => setState(() => _items.removeAt(index)),
                  onEdit: _comingSoon,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "Subcategory" toggle row that heads the category list.
class _SubcategoryRow extends StatelessWidget {
  const _SubcategoryRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52.h,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'categories.subcategory'.tr(),
                    style: context.textTheme.titleSmall?.copyWith(
                      color: context.colors.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                PillToggle(value: value, onChanged: onChanged),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Divider(
            height: 1,
            thickness: 1,
            color: context.colors.outlineVariant,
          ),
        ),
      ],
    );
  }
}

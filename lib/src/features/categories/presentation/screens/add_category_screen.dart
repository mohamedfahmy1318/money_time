import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/categories/presentation/models/category.dart';
import 'package:mony_time/src/features/categories/presentation/widgets/color_swatch.dart';
import 'package:mony_time/src/features/categories/presentation/widgets/icon_option_tile.dart';

/// Create a category: choose an icon, a type, a name and an accent colour.
/// UI-only for now — nothing is persisted yet.
class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  TransactionType _type = TransactionType.expense;
  String _emoji = CategorySampleData.icons.first;
  int _colorIndex = 0;
  final TextEditingController _nameController =
      TextEditingController(text: 'Food & Dining');

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color get _color => CategorySampleData.palette[_colorIndex];

  /// A 135° sweep derived from the selected accent colour.
  Gradient get _previewGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.lerp(_color, Colors.white, 0.28)!, _color],
      );

  void _save() {
    showToast(context, message: 'categories.saved'.tr(), status: 'success');
    context.popOrGo(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'categories.add_title'.tr()),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _iconPreview(context),
                    SizedBox(height: 12.h),
                    Text(
                      'categories.tap_to_choose'.tr(),
                      textAlign: TextAlign.center,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.colors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5.sp,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    TransactionTypeToggle(
                      value: _type,
                      onChanged: (t) => setState(() => _type = t),
                      style: SegmentedToggleStyle.soft,
                      order: const [
                        TransactionType.expense,
                        TransactionType.income,
                      ],
                    ),
                    SizedBox(height: 14.h),
                    AppTextField(
                      controller: _nameController,
                      hint: 'categories.name_hint'.tr(),
                    ),
                    SizedBox(height: 18.h),
                    Text(
                      'categories.color'.tr(),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5.sp,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    _colorRow(),
                    SizedBox(height: 16.h),
                    _iconGrid(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
              child: AppGradientButton(
                label: 'categories.save'.tr(),
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconPreview(BuildContext context) {
    return Center(
      child: Container(
        width: 70.r,
        height: 70.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: _previewGradient,
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: [
            BoxShadow(
              color: _color.withValues(alpha: 0.4),
              offset: Offset(0, 10.h),
              blurRadius: 20.r,
              spreadRadius: -6.r,
            ),
          ],
        ),
        child: Text(_emoji, style: TextStyle(fontSize: 23.sp)),
      ),
    );
  }

  Widget _colorRow() {
    return SizedBox(
      height: 40.r,
      child: Row(
        children: [
          for (var i = 0; i < CategorySampleData.palette.length; i++) ...[
            if (i > 0) SizedBox(width: 10.w),
            ColorSwatchDot(
              color: CategorySampleData.palette[i],
              selected: i == _colorIndex,
              onTap: () => setState(() => _colorIndex = i),
            ),
          ],
        ],
      ),
    );
  }

  /// Left-aligned 4-per-row grid of tight 44 tiles (matches Figma across all
  /// screen widths, unlike a width-dependent Wrap).
  Widget _iconGrid() {
    const perRow = 4;
    const icons = CategorySampleData.icons;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < icons.length; i += perRow) ...[
          if (i > 0) SizedBox(height: 10.h),
          Row(
            children: [
              for (var j = i; j < i + perRow && j < icons.length; j++) ...[
                if (j > i) SizedBox(width: 10.w),
                IconOptionTile(
                  emoji: icons[j],
                  selected: icons[j] == _emoji,
                  onTap: () => setState(() => _emoji = icons[j]),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/bank_sync/domain/entities/bank_sync_results.dart';
import 'package:mony_time/src/features/bank_sync/presentation/cubits/bank_sync_cubit.dart';
import 'package:mony_time/src/features/categories/presentation/widgets/category_pick_tile.dart';

/// Picks one of the user's active categories of [type] (from the server) for
/// the review screen. Resolves to the choice, or `null` when dismissed.
Future<BankCategory?> showBankCategorySheet(
  BuildContext context, {
  required TransactionType type,
  String? selectedId,
}) {
  context.read<BankSyncCubit>().loadCategories(type);
  return showModalBottomSheet<BankCategory>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => _CategorySheet(type: type, selectedId: selectedId),
  );
}

class _CategorySheet extends StatelessWidget {
  const _CategorySheet({required this.type, this.selectedId});

  final TransactionType type;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final categories = context.select<BankSyncCubit, List<BankCategory>?>(
      (c) => c.state.categories[type],
    );

    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Container(
        constraints: BoxConstraints(maxHeight: context.height * 0.7),
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLowest,
          borderRadius: AppBorders.xxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'bank_sync.pick_category'.tr(),
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 17.sp,
              ),
            ),
            SizedBox(height: 18.h),
            if (categories == null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 32.h),
                child: const AppLoading(),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 14.w,
                    runSpacing: 18.h,
                    children: [
                      for (final category in categories)
                        CategoryPickTile(
                          emoji: category.emoji,
                          label: category.name,
                          selected: category.id == selectedId,
                          onTap: () => Navigator.of(context).pop(category),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

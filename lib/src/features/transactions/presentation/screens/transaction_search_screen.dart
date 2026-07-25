import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/transactions/presentation/cubits/transactions_cubit.dart';
import 'package:mony_time/src/features/transactions/presentation/widgets/transaction_card.dart';
import 'package:mony_time/src/features/transactions/presentation/widgets/transaction_row.dart';
import 'package:mony_time/src/features/transactions/presentation/widgets/type_chip.dart';

/// Live transaction search with an All / Income / Expense scope, a result
/// count + volume line, and tappable result rows.
class TransactionSearchScreen extends StatefulWidget {
  const TransactionSearchScreen({super.key});

  @override
  State<TransactionSearchScreen> createState() =>
      _TransactionSearchScreenState();
}

class _TransactionSearchScreenState extends State<TransactionSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  TransactionType? _type;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionsCubit>().state;
    final query = _controller.text.trim();
    final results = state.search(query, type: _type);
    final volume = results.fold<double>(0, (sum, t) => sum + t.amount);
    final locale = context.locale.toString();

    return Scaffold(
      appBar: AppTopBar(title: 'transactions.search_title'.tr()),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2.h),
              AppTextField(
                controller: _controller,
                hint: 'transactions.search_hint'.tr(),
                autofocus: true,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18.sp,
                  color: context.colors.onSurfaceVariant,
                ),
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  TypeChip(
                    label: 'transactions.all'.tr(),
                    selected: _type == null,
                    onTap: () => setState(() => _type = null),
                  ),
                  SizedBox(width: 8.w),
                  TypeChip(
                    label: 'transactions.income'.tr(),
                    selected: _type == TransactionType.income,
                    onTap: () =>
                        setState(() => _type = TransactionType.income),
                  ),
                  SizedBox(width: 8.w),
                  TypeChip(
                    label: 'transactions.expense'.tr(),
                    selected: _type == TransactionType.expense,
                    onTap: () =>
                        setState(() => _type = TransactionType.expense),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              if (query.isNotEmpty) ...[
                Text(
                  'transactions.search_results'.tr(namedArgs: {
                    'count': '${results.length}',
                    'total': moneyWithSymbol(volume),
                  }),
                  style: context.textTheme.labelMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 10.h),
                Expanded(
                  child: results.isEmpty
                      ? Padding(
                          padding: EdgeInsets.only(top: 24.h),
                          child: Text(
                            'transactions.search_empty'.tr(),
                            textAlign: TextAlign.center,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView(
                          padding: EdgeInsets.only(bottom: 24.h),
                          children: [
                            TransactionCard(
                              rows: [
                                for (final t in results)
                                  TransactionRow(
                                    transaction: t,
                                    title: t.note.isEmpty
                                        ? t.categoryLabel
                                        : t.note,
                                    subtitle:
                                        '${AppDate.shortDate(t.date, locale)} · ${t.source}',
                                    onTap: () => context.push(
                                      AppRoutes.transactionDetail,
                                      extra: t,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

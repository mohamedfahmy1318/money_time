import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/budgets/domain/entities/budget.dart';
import 'package:mony_time/src/features/budgets/presentation/cubits/budgets_cubit.dart';
import 'package:mony_time/src/features/budgets/presentation/widgets/budget_keypad.dart';

/// "{Category} Budget": big amount over the budget keypad; Save persists the
/// limit through the app-wide [BudgetsCubit].
class BudgetEditScreen extends StatefulWidget {
  const BudgetEditScreen({super.key, required this.budget});

  final Budget budget;

  @override
  State<BudgetEditScreen> createState() => _BudgetEditScreenState();
}

class _BudgetEditScreenState extends State<BudgetEditScreen> {
  late String _amount = widget.budget.limit % 1 == 0
      ? widget.budget.limit.toStringAsFixed(0)
      : widget.budget.limit.toStringAsFixed(2);

  /// First digit replaces the seeded value instead of appending.
  bool _pristine = true;

  /// Guards the shared cubit's action stream.
  bool _submitted = false;

  void _onKey(BudgetKey key) {
    switch (key.action) {
      case BudgetKeyAction.digit:
        setState(() {
          if (_pristine) {
            _amount = '';
            _pristine = false;
          }
          if (key.label == '.' && _amount.contains('.')) return;
          if (key.label == '.' && _amount.isEmpty) {
            _amount = '0.';
            return;
          }
          _amount = (_amount + key.label).replaceFirst(RegExp(r'^0+(?=\d)'), '');
        });
      case BudgetKeyAction.backspace:
        setState(() {
          _pristine = false;
          _amount =
              _amount.isEmpty ? '' : _amount.substring(0, _amount.length - 1);
        });
      case BudgetKeyAction.clear:
        setState(() {
          _pristine = false;
          _amount = '';
        });
      case BudgetKeyAction.save:
        _save();
    }
  }

  void _save() {
    final limit = double.tryParse(_amount) ?? 0;
    _submitted = true;
    context
        .read<BudgetsCubit>()
        .setBudget(widget.budget.copyWith(limit: limit));
  }

  void _onStateChanged(BuildContext context, BudgetsState state) {
    if (!_submitted) return;
    switch (state.action) {
      case BudgetsAction.saveSuccess:
        _submitted = false;
        showToast(context, message: 'budgets.saved'.tr());
        context.popOrGo(AppRoutes.budgetSettings);
      case BudgetsAction.failure:
        _submitted = false;
        showToast(
          context,
          message: state.errorMessage ?? 'shared.something_wrong'.tr(),
          status: 'error',
        );
      case BudgetsAction.idle:
      case BudgetsAction.saving:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final display = _amount.isEmpty ? '0' : _amount;

    return BlocListener<BudgetsCubit, BudgetsState>(
      listenWhen: (previous, current) => previous.action != current.action,
      listener: _onStateChanged,
      child: Scaffold(
        appBar: AppTopBar(
          title: 'budgets.edit_title'
              .tr(namedArgs: {'category': widget.budget.categoryLabel}),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              SizedBox(height: 18.h),
              Container(
                width: 60.r,
                height: 60.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer,
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Text(
                  widget.budget.categoryEmoji,
                  style: TextStyle(fontSize: 21.sp),
                ),
              ),
              SizedBox(height: 22.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$kCurrencySymbol ${_formatDisplay(display)}',
                    maxLines: 1,
                    style: context.textTheme.headlineLarge?.copyWith(
                      color: context.colors.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 34.sp,
                      letterSpacing: -0.34,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'budgets.monthly_limit'.tr(
                    namedArgs: {'category': widget.budget.categoryLabel}),
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontSize: 11.8.sp,
                ),
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
                child: BudgetKeypad(onKey: _onKey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Thousands separators on the whole part while typing (`1,200` / `0.5`).
  String _formatDisplay(String raw) {
    final parts = raw.split('.');
    final whole = int.tryParse(parts[0]) ?? 0;
    final grouped = formatNumber(whole);
    return parts.length > 1 ? '$grouped.${parts[1]}' : grouped;
  }
}

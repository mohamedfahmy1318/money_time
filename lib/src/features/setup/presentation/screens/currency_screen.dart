import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/setup/presentation/models/app_currency.dart';
import 'package:mony_time/src/features/setup/presentation/widgets/currency_preview_card.dart';
import 'package:mony_time/src/features/setup/presentation/widgets/selectable_option_tile.dart';
import 'package:mony_time/src/features/setup/presentation/widgets/setup_card.dart';
import 'package:mony_time/src/features/setup/presentation/widgets/setup_header.dart';
import 'package:mony_time/src/features/setup/presentation/widgets/symbol_position_toggle.dart';

/// First-run currency picker with a live gradient preview of the selection.
class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  /// `'auto'` follows the device; otherwise an [AppCurrency.code].
  String _selected = 'auto';
  SymbolPosition _symbolPosition = SymbolPosition.front;

  /// No geo lookup in the UI phase — the device default previews as USD.
  static const _detected = 'USD';

  AppCurrency get _activeCurrency =>
      AppCurrency.byCode(_selected == 'auto' ? _detected : _selected);

  @override
  Widget build(BuildContext context) {
    const currencies = AppCurrency.values;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 25.h),
              SetupHeader(
                title: 'setup.currency_title'.tr(),
                subtitle: 'setup.auto_detected'.tr(),
              ),
              SizedBox(height: 16.h),
              CurrencyPreviewCard(
                currency: _activeCurrency,
                symbolPosition: _symbolPosition,
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: SetupCard(
                  clip: true,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      SelectableOptionTile(
                        leading: '🌐',
                        label: 'setup.auto_device'.tr(),
                        trailing: _detected,
                        selected: _selected == 'auto',
                        onTap: () => setState(() => _selected = 'auto'),
                      ),
                      for (final currency in currencies) ...[
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: context.colors.outlineVariant,
                        ),
                        SelectableOptionTile(
                          leading: currency.flag,
                          label: '${currency.code} · ${currency.name}',
                          selected: _selected == currency.code,
                          onTap: () =>
                              setState(() => _selected = currency.code),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              SymbolPositionToggle(
                value: _symbolPosition,
                onChanged: (position) =>
                    setState(() => _symbolPosition = position),
              ),
              SizedBox(height: 14.h),
              AppGradientButton(
                label: 'shared.continue_action'.tr(),
                onPressed: () => context.go(AppRoutes.enableFeatures),
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }
}

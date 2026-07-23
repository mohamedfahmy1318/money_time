import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/setup/presentation/models/app_language.dart';
import 'package:mony_time/src/features/setup/presentation/widgets/selectable_option_tile.dart';
import 'package:mony_time/src/features/setup/presentation/widgets/setup_card.dart';
import 'package:mony_time/src/features/setup/presentation/widgets/setup_header.dart';

/// First-run language picker. Selecting a supported language switches the app
/// locale immediately (easy_localization persists it); unsupported entries are
/// recorded but leave the UI language unchanged.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  /// `'auto'` follows the device; otherwise an [AppLanguage.code].
  String _selected = 'auto';

  AppLanguage get _detected =>
      AppLanguage.byCode(context.deviceLocale.languageCode);

  Future<void> _continue() async {
    final AppLanguage picked =
        _selected == 'auto' ? _detected : AppLanguage.byCode(_selected);

    if (picked.locale != null && picked.locale != context.locale) {
      await context.setLocale(picked.locale!);
    }
    if (!mounted) return;
    context.go(AppRoutes.currency);
  }

  @override
  Widget build(BuildContext context) {
    const languages = AppLanguage.values;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 25.h),
              SetupHeader(
                title: 'setup.language_title'.tr(),
                subtitle: 'setup.auto_detected'.tr(),
              ),
              SizedBox(height: 18.h),
              SetupCard(
                clip: true,
                child: SelectableOptionTile(
                  leading: '🌐',
                  label: 'setup.auto_device'.tr(),
                  trailing: _detected.name,
                  selected: _selected == 'auto',
                  onTap: () => setState(() => _selected = 'auto'),
                ),
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: SetupCard(
                  clip: true,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: languages.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 1,
                      color: context.colors.outlineVariant,
                    ),
                    itemBuilder: (context, index) {
                      final language = languages[index];
                      return SelectableOptionTile(
                        leading: language.flag,
                        label: language.name,
                        selected: _selected == language.code,
                        onTap: () =>
                            setState(() => _selected = language.code),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              AppGradientButton(
                label: 'shared.continue_action'.tr(),
                onPressed: _continue,
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }
}

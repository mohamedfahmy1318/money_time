import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/profile/presentation/widgets/profile_menu_row.dart';

// Theme-preview swatches — illustration-only colours for the mockup cards, not
// theme tokens (there is no dark ColorScheme to read them from yet).
const Color _darkCardBg = Color(0xFF0C1526);
const Color _darkCardBorder = Color(0xFF20324C);
const Color _darkBar = Color(0xFF20324C);
const Color _lightBar = Color(0xFFE2ECEA);

enum _ThemeMode { system, dark, light }

/// Appearance: choose the theme mode over a light / dark preview pair. The
/// selection is local for the UI phase — wiring it to a real theme controller
/// comes later.
class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  _ThemeMode _mode = _ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'settings.appearance'.tr()),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 4.h),
              _row(_ThemeMode.system, Icons.brightness_auto_rounded,
                  'settings.appearance_system'.tr()),
              _divider(),
              _row(_ThemeMode.dark, Icons.dark_mode_outlined,
                  'settings.appearance_dark'.tr()),
              _divider(),
              _row(_ThemeMode.light, Icons.light_mode_outlined,
                  'settings.appearance_light'.tr()),
              SizedBox(height: 24.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Row(
                  children: [
                    const Expanded(child: _Preview(dark: false)),
                    SizedBox(width: 20.w),
                    const Expanded(child: _Preview(dark: true)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(_ThemeMode mode, IconData icon, String label) => ProfileMenuRow(
        icon: icon,
        label: label,
        onTap: () => setState(() => _mode = mode),
        trailing: _Radio(selected: _mode == mode),
      );

  Widget _divider() => Divider(
        height: 1,
        thickness: 1,
        color: context.colors.outlineVariant,
      );
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20.r,
      height: 20.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? context.colors.primary : null,
        shape: BoxShape.circle,
        border: selected
            ? null
            : Border.all(color: context.colors.outlineVariant, width: 2),
      ),
      child: selected
          ? Container(
              width: 7.r,
              height: 7.r,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final barColor = dark ? _darkBar : _lightBar;

    return Container(
      height: 150.h,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: dark ? _darkCardBg : context.colors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: dark ? _darkCardBorder : context.colors.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: dark ? 0.2 : 0.08),
            offset: Offset(0, 8.h),
            blurRadius: 10.r,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 34.h,
            decoration: BoxDecoration(
              gradient: AppGradients.primaryButton,
              borderRadius: BorderRadius.circular(9.r),
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            height: 8.h,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          SizedBox(height: 6.h),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              height: 8.h,
              width: 56.w,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

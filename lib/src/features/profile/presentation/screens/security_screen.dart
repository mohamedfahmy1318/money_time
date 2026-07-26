import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

/// Security: a passcode entry screen. The keypad drives a local 4-digit buffer
/// for the UI phase — nothing is validated or stored yet.
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  static const _length = 4;
  String _code = '';

  void _append(String digit) {
    if (_code.length >= _length) return;
    setState(() => _code += digit);
  }

  void _delete() {
    if (_code.isEmpty) return;
    setState(() => _code = _code.substring(0, _code.length - 1));
  }

  void _faceId() =>
      showToast(context, message: 'profile.coming_soon'.tr(), status: 'info');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: '', isTransparent: true),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Icon(
                Icons.lock_outline_rounded,
                size: 56.sp,
                color: context.colors.primary,
              ),
              SizedBox(height: 18.h),
              Text(
                'security.enter_passcode'.tr(),
                style: context.textTheme.headlineSmall?.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 25.sp,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'security.subtitle'.tr(),
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontSize: 14.sp,
                  height: 1.55,
                ),
              ),
              SizedBox(height: 28.h),
              _Dots(filled: _code.length, total: _length),
              SizedBox(height: 28.h),
              _Keypad(
                onDigit: _append,
                onDelete: _delete,
                onFaceId: _faceId,
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.filled, required this.total});

  final int filled;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          Container(
            width: 15.r,
            height: 15.r,
            margin: EdgeInsets.symmetric(horizontal: 8.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled ? context.colors.primary : null,
              border: i < filled
                  ? null
                  : Border.all(color: context.colors.outlineVariant, width: 2),
            ),
          ),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onDelete,
    required this.onFaceId,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onFaceId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            children: [for (final d in row) _digit(context, d)],
          ),
        Row(
          children: [
            _key(context, Icon(Icons.face_rounded,
                size: 26.sp, color: context.colors.primary), onFaceId),
            _digit(context, '0'),
            _key(context, Icon(Icons.backspace_outlined,
                size: 22.sp, color: context.colors.onSurface), onDelete),
          ],
        ),
      ],
    );
  }

  Widget _digit(BuildContext context, String digit) => _key(
        context,
        Text(
          digit,
          style: context.textTheme.headlineSmall?.copyWith(
            color: context.colors.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 24.sp,
          ),
        ),
        () => onDigit(digit),
      );

  Widget _key(BuildContext context, Widget child, VoidCallback onTap) =>
      Expanded(
        child: InkResponse(
          onTap: onTap,
          radius: 32.r,
          child: SizedBox(height: 58.h, child: Center(child: child)),
        ),
      );
}

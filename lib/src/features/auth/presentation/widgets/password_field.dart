import 'package:mony_time/src/imports/core_imports.dart';

/// [AppTextField] specialized for passwords — owns its obscure toggle so
/// screens don't carry that state.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label,
    this.enabled = true,
    this.validator,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String? label;
  final bool enabled;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      enabled: widget.enabled,
      label: widget.label ?? 'auth.password'.tr(),
      obscureText: _obscure,
      validator: widget.validator ?? AppValidators.password,
      textInputAction: widget.textInputAction,
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}

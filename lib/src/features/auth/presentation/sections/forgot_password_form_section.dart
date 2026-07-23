import 'package:mony_time/src/imports/core_imports.dart';

/// Email field + send-reset-link button.
class ForgotPasswordFormSection extends StatelessWidget {
  const ForgotPasswordFormSection({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.isLoading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          AppTextField(
            controller: emailController,
            enabled: !isLoading,
            hint: 'auth.email_address'.tr(),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: AppValidators.email,
          ),
          SizedBox(height: AppSpacing.lg),
          AppGradientButton(
            label: 'auth.send_reset_link'.tr(),
            isLoading: isLoading,
            onPressed: isLoading ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}

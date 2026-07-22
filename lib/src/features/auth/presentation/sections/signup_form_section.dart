import 'package:mony_time/src/imports/core_imports.dart';

import 'package:mony_time/src/features/auth/presentation/widgets/password_field.dart';

/// Name + email + password + confirm-password form with submit.
class SignupFormSection extends StatelessWidget {
  const SignupFormSection({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isLoading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          AppTextField(
            controller: nameController,
            enabled: !isLoading,
            label: 'auth.name'.tr(),
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.person_outline),
            validator: AppValidators.name,
          ),
          SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: emailController,
            enabled: !isLoading,
            label: 'auth.email'.tr(),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.email_outlined),
            validator: AppValidators.email,
          ),
          SizedBox(height: AppSpacing.md),
          PasswordField(
            controller: passwordController,
            enabled: !isLoading,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: AppSpacing.md),
          PasswordField(
            controller: confirmPasswordController,
            enabled: !isLoading,
            label: 'auth.confirm_password'.tr(),
            textInputAction: TextInputAction.done,
            validator:
                AppValidators.confirmPassword(() => passwordController.text),
          ),
          SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'auth.sign_up'.tr(),
            isLoading: isLoading,
            onPressed: isLoading ? null : onSubmit,
            width: ButtonSize.large,
          ),
        ],
      ),
    );
  }
}

import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/auth/presentation/widgets/password_field.dart';
import 'package:mony_time/src/features/auth/presentation/widgets/terms_checkbox.dart';

/// Registration block: name, email, password, the terms agreement, and the
/// Create Account action.
class SignupFormSection extends StatelessWidget {
  const SignupFormSection({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.agreedToTerms,
    required this.onAgreedChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final bool agreedToTerms;
  final ValueChanged<bool> onAgreedChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: nameController,
            enabled: !isLoading,
            hint: 'auth.full_name'.tr(),
            textInputAction: TextInputAction.next,
            validator: AppValidators.name,
          ),
          SizedBox(height: 11.h),
          AppTextField(
            controller: emailController,
            enabled: !isLoading,
            hint: 'auth.email_address'.tr(),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: AppValidators.email,
          ),
          SizedBox(height: 11.h),
          PasswordField(
            controller: passwordController,
            enabled: !isLoading,
            textInputAction: TextInputAction.done,
          ),
          SizedBox(height: 14.h),
          TermsCheckbox(value: agreedToTerms, onChanged: onAgreedChanged),
          SizedBox(height: 14.h),
          AppGradientButton(
            label: 'auth.create_account_button'.tr(),
            isLoading: isLoading,
            onPressed: isLoading ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}

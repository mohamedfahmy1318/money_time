import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/auth/presentation/widgets/password_field.dart';

/// Email + password form with remember-me / forgot-password row and submit.
class LoginFormSection extends StatefulWidget {
  const LoginFormSection({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  State<LoginFormSection> createState() => _LoginFormSectionState();
}

class _LoginFormSectionState extends State<LoginFormSection> {
  bool _rememberMe = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          AppTextField(
            controller: widget.emailController,
            enabled: !widget.isLoading,
            label: 'auth.email'.tr(),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.email_outlined),
            validator: AppValidators.email,
          ),
          SizedBox(height: AppSpacing.md),
          PasswordField(
            controller: widget.passwordController,
            enabled: !widget.isLoading,
            textInputAction: TextInputAction.done,
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: 5.w,
                children: [
                  SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (value) =>
                          setState(() => _rememberMe = value ?? false),
                    ),
                  ),
                  Text(
                    'auth.remember_me'.tr(),
                    style: context.textTheme.bodySmall
                        ?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
              TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () => context.push(AppRoutes.forgotPassword),
                child: Text(
                  'auth.forgot_password'.tr(),
                  style: context.textTheme.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'auth.sign_in'.tr(),
            isLoading: widget.isLoading,
            onPressed: widget.isLoading ? null : widget.onSubmit,
            width: ButtonSize.large,
          ),
        ],
      ),
    );
  }
}

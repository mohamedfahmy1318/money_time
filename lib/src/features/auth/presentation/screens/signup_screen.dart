import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/auth/auth_di.dart';
import 'package:mony_time/src/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:mony_time/src/features/auth/presentation/sections/signup_form_section.dart';
import 'package:mony_time/src/features/auth/presentation/widgets/auth_footer_link.dart';
import 'package:mony_time/src/features/auth/presentation/widgets/auth_header.dart';
import 'package:mony_time/src/features/auth/presentation/widgets/auth_or_divider.dart';
import 'package:mony_time/src/features/auth/presentation/widgets/social_auth_button.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthDi.authCubit(),
      child: const _SignupBody(),
    );
  }
}

class _SignupBody extends StatefulWidget {
  const _SignupBody();

  @override
  State<_SignupBody> createState() => _SignupBodyState();
}

class _SignupBodyState extends State<_SignupBody> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_agreedToTerms) {
      showToast(context,
          message: 'auth.must_agree_terms'.tr(), status: 'warning');
      return;
    }
    context.hideKeyboard();
    context.read<AuthCubit>().signUp(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _onStateChanged(BuildContext context, AuthState state) {
    switch (state.status) {
      case AuthStatus.failure:
        showToast(context, message: state.errorMessage ?? '', status: 'error');
      case AuthStatus.authenticated:
        // Session is committed at the end of the welcome funnel, not here.
        context.go(AppRoutes.connectShortcuts, extra: state.user);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: _onStateChanged,
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: 39.h),
                          AuthHeader(
                            title: 'auth.create_account_title'.tr(),
                            subtitle: 'auth.start_managing'.tr(),
                          ),
                          SizedBox(height: 24.h),
                          SignupFormSection(
                            formKey: _formKey,
                            nameController: _nameController,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            isLoading: state.isLoading,
                            agreedToTerms: _agreedToTerms,
                            onAgreedChanged: (v) =>
                                setState(() => _agreedToTerms = v),
                            onSubmit: _submit,
                          ),
                          SizedBox(height: 16.h),
                          const AuthOrDivider(),
                          SizedBox(height: 18.h),
                          Row(
                            children: [
                              Expanded(
                                child: SocialAuthButton(
                                  asset: AppAssets.googleColorIcon,
                                  dark: false,
                                  onPressed: () {},
                                ),
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: SocialAuthButton(
                                  asset: AppAssets.appleIcon,
                                  dark: true,
                                  onPressed: () {},
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                  AuthFooterLink(
                    prompt: 'auth.already_have_account'.tr(),
                    action: 'auth.log_in_button'.tr(),
                    onTap: () => context.popOrGo(AppRoutes.login),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

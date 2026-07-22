import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/auth/auth_di.dart';
import 'package:mony_time/src/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:mony_time/src/features/auth/presentation/cubits/session_cubit.dart';
import 'package:mony_time/src/features/auth/presentation/sections/login_form_section.dart';
import 'package:mony_time/src/features/auth/presentation/sections/social_login_section.dart';
import 'package:mony_time/src/features/auth/presentation/widgets/auth_footer_link.dart';
import 'package:mony_time/src/features/auth/presentation/widgets/auth_header.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthDi.authCubit(),
      child: const _LoginBody(),
    );
  }
}

class _LoginBody extends StatefulWidget {
  const _LoginBody();

  @override
  State<_LoginBody> createState() => _LoginBodyState();
}

class _LoginBodyState extends State<_LoginBody> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.hideKeyboard();
    context.read<AuthCubit>().login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _onStateChanged(BuildContext context, AuthState state) {
    switch (state.status) {
      case AuthStatus.failure:
        showToast(context, message: state.errorMessage ?? '', status: 'error');
      case AuthStatus.authenticated:
        context.read<SessionCubit>().setUser(state.user!);
        context.go(AppRoutes.home);
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
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    SizedBox(height: AppSpacing.xl),
                    AuthHeader(
                      title: 'auth.log_in'.tr(),
                      subtitle: 'auth.log_in_subtitle'.tr(),
                    ),
                    SizedBox(height: AppSpacing.xxxl),
                    LoginFormSection(
                      formKey: _formKey,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      isLoading: state.isLoading,
                      onSubmit: _submit,
                    ),
                    SizedBox(height: AppSpacing.xxxl),
                    const SocialLoginSection(),
                    SizedBox(height: AppSpacing.xl),
                    AuthFooterLink(
                      prompt: 'auth.dont_have_account'.tr(),
                      action: 'auth.sign_up'.tr(),
                      onTap: () => context.push(AppRoutes.signup),
                    ),
                    SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

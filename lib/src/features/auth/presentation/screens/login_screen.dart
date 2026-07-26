import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/auth/auth_di.dart';
import 'package:mony_time/src/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:mony_time/src/features/auth/presentation/cubits/session_cubit.dart';
import 'package:mony_time/src/features/auth/presentation/models/auth_gate.dart';
import 'package:mony_time/src/features/auth/presentation/sections/login_form_section.dart';
import 'package:mony_time/src/features/auth/presentation/widgets/auth_footer_link.dart';
import 'package:mony_time/src/features/auth/presentation/widgets/auth_header.dart';
import 'package:mony_time/src/features/auth/presentation/widgets/auth_logo.dart';
import 'package:mony_time/src/features/auth/presentation/widgets/auth_or_divider.dart';
import 'package:mony_time/src/features/auth/presentation/widgets/social_auth_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, this.gate});

  /// Set when a guest reached login from a protected action — where to resume
  /// once signed in.
  final AuthGate? gate;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthDi.authCubit(),
      child: _LoginBody(gate: gate),
    );
  }
}

class _LoginBody extends StatefulWidget {
  const _LoginBody({this.gate});

  final AuthGate? gate;

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
        final user = state.user;
        if (user != null) context.read<SessionCubit>().setUser(user);
        final gate = widget.gate;
        // Returning sign-in skips the welcome funnel: resume the pending action
        // if any, otherwise land on home.
        if (gate != null) {
          context.pushReplacement(gate.returnRoute, extra: gate.returnExtra);
        } else {
          context.go(AppRoutes.home);
        }
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
                          SizedBox(height: 26.h),
                          const AuthLogo(),
                          SizedBox(height: 27.h),
                          AuthHeader(
                            title: 'auth.welcome_back'.tr(),
                            subtitle: 'auth.log_in_to_continue'.tr(),
                          ),
                          SizedBox(height: 25.h),
                          LoginFormSection(
                            formKey: _formKey,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            isLoading: state.isLoading,
                            onSubmit: _submit,
                            onForgot: () =>
                                context.push(AppRoutes.forgotPassword),
                          ),
                          SizedBox(height: 17.h),
                          const AuthOrDivider(),
                          SizedBox(height: 18.h),
                          SocialAuthButton(
                            asset: AppAssets.googleColorIcon,
                            dark: false,
                            label: 'auth.continue_google'.tr(),
                            onPressed: () {},
                          ),
                          SizedBox(height: 12.h),
                          SocialAuthButton(
                            asset: AppAssets.appleIcon,
                            dark: true,
                            label: 'auth.continue_apple'.tr(),
                            onPressed: () {},
                          ),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                  AuthFooterLink(
                    prompt: 'auth.dont_have_account'.tr(),
                    action: 'auth.sign_up'.tr(),
                    onTap: () =>
                        context.push(AppRoutes.signup, extra: widget.gate),
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

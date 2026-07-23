import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/auth/auth_di.dart';
import 'package:mony_time/src/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:mony_time/src/features/auth/presentation/cubits/session_cubit.dart';
import 'package:mony_time/src/features/auth/presentation/sections/signup_form_section.dart';
import 'package:mony_time/src/features/auth/presentation/widgets/auth_footer_link.dart';
import 'package:mony_time/src/features/auth/presentation/widgets/auth_header.dart';

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
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
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
                      title: 'auth.sign_up'.tr(),
                      subtitle: 'auth.sign_up_subtitle'.tr(),
                    ),
                    SizedBox(height: AppSpacing.xxxl),
                    SignupFormSection(
                      formKey: _formKey,
                      nameController: _nameController,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                      isLoading: state.isLoading,
                      onSubmit: _submit,
                    ),
                    SizedBox(height: AppSpacing.xxxl),
                    AuthFooterLink(
                      prompt: 'auth.already_have_account'.tr(),
                      action: 'auth.log_in'.tr(),
                      onTap: () => context.popOrGo(AppRoutes.login),
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

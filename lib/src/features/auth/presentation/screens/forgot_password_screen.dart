import 'package:mony_time/src/imports/core_imports.dart';
import 'package:mony_time/src/imports/packages_imports.dart';

import 'package:mony_time/src/features/auth/auth_di.dart';
import 'package:mony_time/src/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:mony_time/src/features/auth/presentation/sections/forgot_password_form_section.dart';
import 'package:mony_time/src/features/auth/presentation/widgets/auth_header.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthDi.authCubit(),
      child: const _ForgotPasswordBody(),
    );
  }
}

class _ForgotPasswordBody extends StatefulWidget {
  const _ForgotPasswordBody();

  @override
  State<_ForgotPasswordBody> createState() => _ForgotPasswordBodyState();
}

class _ForgotPasswordBodyState extends State<_ForgotPasswordBody> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.hideKeyboard();
    context.read<AuthCubit>().forgotPassword(
          email: _emailController.text.trim(),
        );
  }

  void _onStateChanged(BuildContext context, AuthState state) {
    switch (state.status) {
      case AuthStatus.failure:
        showToast(context, message: state.errorMessage ?? '', status: 'error');
      case AuthStatus.resetLinkSent:
        showToast(context,
            message: 'auth.reset_link_sent'.tr(), status: 'success');
        context.popOrGo(AppRoutes.login);
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
          appBar: const AppTopBar(title: ''),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    SizedBox(height: AppSpacing.xl),
                    AuthHeader(
                      title: 'auth.forgot_password_title'.tr(),
                      subtitle: 'auth.forgot_password_subtitle'.tr(),
                    ),
                    SizedBox(height: AppSpacing.xxxl),
                    ForgotPasswordFormSection(
                      formKey: _formKey,
                      emailController: _emailController,
                      isLoading: state.isLoading,
                      onSubmit: _submit,
                    ),
                    SizedBox(height: AppSpacing.xxxl),
                    TextButton(
                      onPressed: () => context.popOrGo(AppRoutes.login),
                      child: Text(
                        'auth.back_to_login'.tr(),
                        style: context.textTheme.labelLarge?.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

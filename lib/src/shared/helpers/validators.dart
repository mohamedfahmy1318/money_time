import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../../utils/app_utils.dart';

/// Reusable form validators — keeps validation logic out of widgets.
///
/// Usage: `AppTextField(validator: AppValidators.email)`.
abstract final class AppValidators {
  AppValidators._();

  static String? email(String? value) {
    if (AppUtils.isBlank(value)) return 'auth.email_required'.tr();
    if (!AppUtils.isValidEmail(value!)) return 'auth.email_invalid'.tr();
    return null;
  }

  static String? password(String? value) {
    if (AppUtils.isBlank(value)) return 'auth.password_required'.tr();
    if (value!.length < 6) return 'auth.password_too_short'.tr();
    return null;
  }

  static String? name(String? value) {
    if (AppUtils.isBlank(value)) return 'auth.name_required'.tr();
    return null;
  }

  /// Validator for a confirm-password field matching [original].
  static FormFieldValidator<String> confirmPassword(
    String Function() original,
  ) {
    return (value) {
      if (AppUtils.isBlank(value)) return 'auth.confirm_password_required'.tr();
      if (value != original()) return 'auth.passwords_do_not_match'.tr();
      return null;
    };
  }
}

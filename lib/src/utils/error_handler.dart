import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import 'api_error.dart';
import 'failure.dart';

class AppErrorHandler {
  /// Maps anything thrown by a datasource to the [Failure] the UI shows: the
  /// server's translated message (first field message on validation errors)
  /// with its error code, a localized "no connection" when the request never
  /// got an answer, else a generic message. Exception text never reaches a
  /// toast — it stays in [Failure.error] for the log.
  static Failure toFailure(Object error) {
    if (error is DioException) {
      final api = ApiError.fromDio(error);
      if (api != null) {
        return ServerFailure(
          api.displayMessage,
          error: api,
          code: api.code,
          status: api.status,
        );
      }
      if (ApiError.isConnectionProblem(error)) {
        return NetworkFailure('shared.no_connection'.tr(), error: error);
      }
      return ServerFailure(
        'shared.something_wrong'.tr(),
        error: error,
        status: error.response?.statusCode,
      );
    }
    if (error is PlatformException) {
      // Native code names what went wrong (`PERMISSION_DENIED`,
      // `KEYSTORE_FAILED`…) for callers that branch on it.
      return ServerFailure(
        'shared.something_wrong'.tr(),
        error: error,
        code: error.code,
      );
    }
    return ServerFailure('shared.something_wrong'.tr(), error: error);
  }

  static String format(dynamic error) {
    if (error is String) return error;

    try {
      if (error?.message != null) return error.message;
      if (error?.toString() != null) return error.toString();
    } catch (_) {}

    return 'An unexpected error occurred';
  }
}

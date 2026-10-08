import 'dart:io';

import 'package:dio/dio.dart';

/// A non-2xx response from the Money Time API, read from its error envelope:
/// `{"error": {"code", "message", "fields", "request_id"}}`.
///
/// [message] is already translated by the server (from `Accept-Language`) and
/// safe to show; logic branches on [code] only, never on the text.
class ApiError {
  const ApiError({
    required this.status,
    required this.code,
    required this.message,
    this.fields = const {},
    this.requestId,
    this.retryAfter,
  });

  final int? status;
  final String code;
  final String message;

  /// Validation messages per request field (`VALIDATION_FAILED` only).
  final Map<String, List<String>> fields;
  final String? requestId;

  /// From the `Retry-After` header on `429 RATE_LIMITED`.
  final Duration? retryAfter;

  /// What a form shows: the first field message, else the envelope message.
  String get displayMessage {
    for (final messages in fields.values) {
      if (messages.isNotEmpty) return messages.first;
    }
    return message;
  }

  /// Parses the envelope, or `null` when the response carries none (network
  /// failure, proxy error page, …).
  static ApiError? fromDio(DioException e) {
    final data = e.response?.data;
    final error = data is Map ? data['error'] : null;
    if (error is! Map) return null;

    final fields = <String, List<String>>{};
    final rawFields = error['fields'];
    if (rawFields is Map) {
      rawFields.forEach((key, value) {
        if (value is List) fields['$key'] = [for (final m in value) '$m'];
      });
    }
    final retryAfter =
        int.tryParse(e.response?.headers.value('retry-after') ?? '');

    return ApiError(
      status: e.response?.statusCode,
      code: '${error['code'] ?? 'UNKNOWN'}',
      message: '${error['message'] ?? ''}',
      fields: fields,
      requestId: error['request_id']?.toString(),
      retryAfter: retryAfter == null ? null : Duration(seconds: retryAfter),
    );
  }

  /// The request never got an answer — offline, DNS, timeout.
  static bool isConnectionProblem(DioException e) => switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError =>
          true,
        DioExceptionType.unknown => e.error is SocketException,
        _ => false,
      };

  @override
  String toString() => 'ApiError($status $code, request ${requestId ?? '-'})';
}

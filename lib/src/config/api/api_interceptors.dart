import 'package:dio/dio.dart';

import 'package:mony_time/src/config/api/api_session.dart';
import 'package:mony_time/src/utils/api_error.dart';
import 'package:mony_time/src/utils/logger.dart';

/// `Options.extra` flag for public endpoints (login, signup, banks catalog):
/// no `Authorization` header, and a `401` there never touches the session.
const String kSkipAuth = 'skip_auth';

const String _kRetried = 'auth_retried';

/// Adds the headers the server reads on every request: `Accept-Language`
/// (translated errors and category labels), `X-Device-Id` (one session per
/// install), and `X-Platform` + `X-App-Version` (minimum-version check).
class ApiHeadersInterceptor extends Interceptor {
  ApiHeadersInterceptor(this._session);

  final ApiSession _session;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.addAll({
      'Accept-Language': _session.language,
      'X-Device-Id': _session.deviceId,
      'X-Platform': _session.platform,
      'X-App-Version': _session.appVersion,
    });
    handler.next(options);
  }
}

enum _RefreshOutcome { refreshed, rejected, failed }

/// Signs requests with the access token and keeps it fresh.
///
/// On `401 TOKEN_EXPIRED` it refreshes **once** and retries the request once
/// with the new token. Only one refresh runs at a time — presenting an
/// already-rotated refresh token revokes the whole session server-side — so
/// parallel failures all wait on the same refresh. A rejected refresh or a
/// `401 UNAUTHENTICATED` ends the session locally; a refresh that merely
/// failed (offline, 5xx) keeps it.
class ApiAuthInterceptor extends Interceptor {
  ApiAuthInterceptor({
    required Dio dio,
    required Dio refreshClient,
    required ApiSession session,
  })  : _dio = dio,
        _refreshClient = refreshClient,
        _session = session;

  final Dio _dio;

  /// Bare client (headers only) so the refresh call can't recurse in here.
  final Dio _refreshClient;
  final ApiSession _session;

  Future<_RefreshOutcome>? _refreshing;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _session.accessToken;
    if (options.extra[kSkipAuth] != true &&
        token != null &&
        !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 || options.extra[kSkipAuth] == true) {
      return handler.next(err);
    }

    final code = ApiError.fromDio(err)?.code;
    if (code == 'TOKEN_EXPIRED' && options.extra[_kRetried] != true) {
      final sentToken = _bearerOf(options);
      // Another call already rotated the pair while this one was in flight:
      // just retry with the current token instead of refreshing again.
      final outcome = sentToken != null && sentToken != _session.accessToken
          ? _RefreshOutcome.refreshed
          : await (_refreshing ??=
              _refresh().whenComplete(() => _refreshing = null));

      if (outcome == _RefreshOutcome.refreshed &&
          _session.accessToken != null) {
        options.extra[_kRetried] = true;
        options.headers['Authorization'] = 'Bearer ${_session.accessToken}';
        try {
          return handler.resolve(await _dio.fetch<dynamic>(options));
        } on DioException catch (retryError) {
          return handler.next(retryError);
        }
      }
      if (outcome == _RefreshOutcome.rejected) await _session.endSession();
      // The session is fine, the refresh just didn't get through (offline,
      // 5xx, 429): report that, not "your session has expired".
      if (outcome == _RefreshOutcome.failed) {
        final cause = _refreshFailure;
        return handler.next(cause == null
            ? err
            : DioException(
                requestOptions: options,
                response: cause.response,
                type: cause.type,
                error: cause.error,
                message: cause.message,
              ));
      }
    } else if (code == 'UNAUTHENTICATED' || code == 'TOKEN_EXPIRED') {
      await _session.endSession();
    }
    handler.next(err);
  }

  /// Why the last refresh failed, rewritten onto the request that needed it.
  DioException? _refreshFailure;

  Future<_RefreshOutcome> _refresh() async {
    final refreshToken = _session.refreshToken;
    if (refreshToken == null) return _RefreshOutcome.rejected;
    _refreshFailure = null;
    try {
      final response = await _refreshClient.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final tokens = response.data!['tokens'] as Map<String, dynamic>;
      await _session.saveTokens(
        access: tokens['access_token'] as String,
        refresh: tokens['refresh_token'] as String,
      );
      return _RefreshOutcome.refreshed;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      AppLogger.warning('Token refresh failed: $status');
      // 401 INVALID_REFRESH_TOKEN (or a malformed token): the session is over.
      // Anything else (offline, 429, 5xx) may succeed later — keep it.
      if (status == 401 || status == 422) return _RefreshOutcome.rejected;
      _refreshFailure = e;
      return _RefreshOutcome.failed;
    } catch (e) {
      // An unexpected response shape must not leave the caller hanging.
      AppLogger.error('Token refresh broke: $e');
      return _RefreshOutcome.failed;
    }
  }

  static String? _bearerOf(RequestOptions options) {
    final header = options.headers['Authorization'];
    if (header is! String || !header.startsWith('Bearer ')) return null;
    return header.substring(7);
  }
}

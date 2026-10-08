import '../imports/core_imports.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'api/api_interceptors.dart';
import 'api/api_session.dart';

class AppConfig {
  AppConfig._();
  static late final Dio dio;

  /// Production API; `.env` `API_BASE_URL` overrides it (e.g. staging).
  static const String defaultBaseUrl = 'https://moneytime.findosystem.com/v1';

  /// Features still on stub data: their data sources return in-memory
  /// responses instead of hitting the network. Auth and bank messages are
  /// live; transactions, budgets and the rest flip once they are wired.
  static const bool useMockData = true;

  static String get baseUrl => _getBaseUrl();

  static Future<void> init() async {
    final options = BaseOptions(
      baseUrl: _getBaseUrl(),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
      headers: {'Accept': 'application/json'},
    );
    final session = ApiSession.instance;
    final headers = ApiHeadersInterceptor(session);
    final refreshClient = Dio(options)..interceptors.add(headers);

    final client = Dio(options);
    client.interceptors.addAll([
      headers,
      ApiAuthInterceptor(
        dio: client,
        refreshClient: refreshClient,
        session: session,
      ),
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.info('🌐 [DIO] REQUEST[${options.method}] => PATH: ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.info('✅ [DIO] RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          final api = ApiError.fromDio(e);
          AppLogger.error(
            '❌ [DIO] ERROR[${e.response?.statusCode} ${api?.code ?? e.type.name}] '
            '=> PATH: ${e.requestOptions.path} (${api?.requestId ?? 'no request id'})',
          );
          return handler.next(e);
        },
      ),
    ]);
    dio = client;
  }

  static String _getBaseUrl() {
    final value = dotenv.maybeGet('API_BASE_URL')?.trim() ?? '';
    return value.startsWith('http') ? value : defaultBaseUrl;
  }
}

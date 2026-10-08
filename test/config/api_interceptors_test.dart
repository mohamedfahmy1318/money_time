import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mony_time/src/config/api/api_interceptors.dart';
import 'package:mony_time/src/config/api/api_session.dart';
import 'package:mony_time/src/utils/error_handler.dart';
import 'package:mony_time/src/utils/failure.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Map<String, dynamic> _error(String code) => {
      'error': {'code': code, 'message': code, 'request_id': 'req_1'},
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final session = ApiSession.instance;

  late int refreshCalls;
  late List<RequestOptions> seen;
  late Dio dio;

  void build({required ResponseBody Function() refreshResponse}) {
    refreshCalls = 0;
    seen = [];
    final adapter = _Adapter((options) async {
      seen.add(options);
      if (options.path == '/auth/refresh') {
        refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return refreshResponse();
      }
      return switch (options.headers['Authorization']) {
        'Bearer fresh' => _json(200, {'ok': true}),
        'Bearer revoked' => _json(401, _error('UNAUTHENTICATED')),
        _ => _json(401, _error('TOKEN_EXPIRED')),
      };
    });
    final options = BaseOptions(baseUrl: 'https://api.test/v1');
    final headers = ApiHeadersInterceptor(session);
    final refreshClient = Dio(options)
      ..httpClientAdapter = adapter
      ..interceptors.add(headers);
    dio = Dio(options)..httpClientAdapter = adapter;
    dio.interceptors.addAll([
      headers,
      ApiAuthInterceptor(
          dio: dio, refreshClient: refreshClient, session: session),
    ]);
  }

  setUp(() async {
    session
      ..deviceId = 'device-1'
      ..appVersion = '1.0.0+1'
      ..language = 'ar';
    await session.saveTokens(access: 'stale', refresh: 'rt_1');
  });

  test('sends the identity headers and the bearer token', () async {
    build(refreshResponse: () => _json(500, {}));
    await session.saveTokens(access: 'fresh', refresh: 'rt_1');
    await dio.get<dynamic>('/me');
    final h = seen.single.headers;
    expect(h['Accept-Language'], 'ar');
    expect(h['X-Device-Id'], 'device-1');
    expect(h['X-App-Version'], '1.0.0+1');
    expect(h['X-Platform'], isNotEmpty);
    expect(h['Authorization'], 'Bearer fresh');
  });

  test('TOKEN_EXPIRED: one refresh for parallel calls, each retried once',
      () async {
    build(
      refreshResponse: () => _json(200, {
        'tokens': {'access_token': 'fresh', 'refresh_token': 'rt_2'},
      }),
    );
    final responses = await Future.wait([
      for (var i = 0; i < 3; i++) dio.get<dynamic>('/bank-sync/summary'),
    ]);
    expect(responses.map((r) => r.statusCode), everyElement(200));
    expect(refreshCalls, 1);
    expect(session.accessToken, 'fresh');
    expect(session.refreshToken, 'rt_2');
  });

  test('a rejected refresh ends the session', () async {
    build(refreshResponse: () => _json(401, _error('INVALID_REFRESH_TOKEN')));
    final ended = session.onSignedOut.first;
    await expectLater(
      dio.get<dynamic>('/bank-sync/summary'),
      throwsA(isA<DioException>()),
    );
    await ended.timeout(const Duration(seconds: 1));
    expect(session.hasSession, isFalse);
  });

  test('an offline refresh keeps the session', () async {
    build(
        refreshResponse: () => throw DioException.connectionError(
              requestOptions: RequestOptions(path: '/auth/refresh'),
              reason: 'offline',
            ));
    await expectLater(
      dio.get<dynamic>('/bank-sync/summary'),
      throwsA(isA<DioException>()),
    );
    expect(session.hasSession, isTrue);
  });

  test('UNAUTHENTICATED signs out without refreshing', () async {
    build(refreshResponse: () => _json(500, {}));
    await session.saveTokens(access: 'revoked', refresh: 'rt_1');
    await expectLater(
      dio.get<dynamic>('/me'),
      throwsA(isA<DioException>()),
    );
    expect(refreshCalls, 0);
    expect(session.hasSession, isFalse);
  });

  test('error envelope → failure with code and the first field message', () {
    final failure = AppErrorHandler.toFailure(DioException(
      requestOptions: RequestOptions(path: '/bank-sync/messages'),
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/bank-sync/messages'),
        statusCode: 422,
        data: {
          'error': {
            'code': 'VALIDATION_FAILED',
            'message': 'Please check the highlighted fields.',
            'fields': {
              'received_at': ['The received at must have a time zone offset.'],
            },
          },
        },
      ),
    ));
    expect(failure, isA<ServerFailure>());
    expect(failure.code, 'VALIDATION_FAILED');
    expect(failure.status, 422);
    expect(failure.message, 'The received at must have a time zone offset.');

    final offline = AppErrorHandler.toFailure(DioException.connectionError(
      requestOptions: RequestOptions(path: '/me'),
      reason: 'offline',
    ));
    expect(offline, isA<NetworkFailure>());
  });
}

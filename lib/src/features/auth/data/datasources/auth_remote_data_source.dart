import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:mony_time/src/config/api/api_interceptors.dart';
import 'package:mony_time/src/config/api/api_session.dart';
import 'package:mony_time/src/config/app_config.dart';
import 'package:mony_time/src/features/auth/data/models/user_model.dart';
import 'package:mony_time/src/services/storage_service.dart';

/// Raw API calls for the auth feature, against the live Money Time API.
///
/// Throws on failure — error mapping happens in the repository via `runTask`.
/// Tokens go to [ApiSession] (secure storage); the signed-in user is also
/// cached locally so a launch without network still opens signed in.
class AuthRemoteDataSource {
  AuthRemoteDataSource({Dio? dio, ApiSession? session})
      : _dio = dio ?? AppConfig.dio,
        _session = session ?? ApiSession.instance;

  final Dio _dio;
  final ApiSession _session;

  static const _cachedUserKey = 'auth.cached_user';
  static final _public = Options(extra: {kSkipAuth: true});

  Stream<void> get sessionEnded => _session.onSignedOut;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
      options: _public,
    );
    return _startSession(response.data!);
  }

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/signup',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'accepted_terms_version': await _termsVersion(),
        'language': _session.language,
      },
      options: _public,
    );
    return _startSession(response.data!);
  }

  Future<void> forgotPassword({required String email}) async {
    await _dio.post<void>(
      '/auth/forgot-password',
      data: {'email': email},
      options: _public,
    );
  }

  /// Ends this device's session server-side (best effort), then locally.
  Future<void> logout() async {
    try {
      if (_session.hasSession) await _dio.post<void>('/auth/logout');
    } on DioException {
      // Offline or already revoked — the local sign-out below still happens.
    } finally {
      await _session.clearTokens();
      await StorageService.instance.remove(_cachedUserKey);
    }
  }

  /// The signed-in user, or `null` for a guest. Offline (or a server
  /// hiccup) falls back to the cached profile so the session survives.
  Future<UserModel?> getCurrentUser() async {
    if (!_session.hasSession) return null;
    try {
      final response = await _dio.get<Map<String, dynamic>>('/me');
      final user = UserModel.fromJson(response.data!);
      await _cache(user);
      return user;
    } on DioException catch (e) {
      // 401 after the refresh attempt: the interceptor already ended it.
      if (e.response?.statusCode == 401) {
        await StorageService.instance.remove(_cachedUserKey);
        return null;
      }
      // Offline, a server hiccup, a rate limit or an "update the app"
      // answer: the session itself is fine, keep the user signed in.
      return _cached();
    }
  }

  Future<UserModel> _startSession(Map<String, dynamic> body) async {
    final tokens = body['tokens'] as Map<String, dynamic>;
    await _session.saveTokens(
      access: tokens['access_token'] as String,
      refresh: tokens['refresh_token'] as String,
    );
    final user = UserModel.fromJson(body);
    await _cache(user);
    return user;
  }

  /// Signup must echo the current terms version from `/app/config`.
  Future<String> _termsVersion() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/app/config',
      options: _public,
    );
    final legal = response.data!['legal'] as Map<String, dynamic>;
    return legal['terms_version'] as String;
  }

  Future<void> _cache(UserModel user) async {
    await StorageService.instance
        .setString(_cachedUserKey, jsonEncode(user.toJson()));
  }

  UserModel? _cached() {
    final raw = StorageService.instance.getString(_cachedUserKey);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return null;
    }
  }
}

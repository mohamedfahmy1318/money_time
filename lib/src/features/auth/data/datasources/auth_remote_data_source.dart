import 'package:dio/dio.dart';

import 'package:mony_time/src/config/app_config.dart';
import 'package:mony_time/src/features/auth/data/models/user_model.dart';

/// Raw API calls for the auth feature.
///
/// Throws on failure — error mapping happens in the repository via `runTask`.
///
/// While [AppConfig.useMockData] is `true` (no backend yet) each method returns
/// a stub after a short delay so the UI flow is fully walkable. The real Dio
/// calls sit right beside the stubs — delete the mock branch to go live.
class AuthRemoteDataSource {
  AuthRemoteDataSource({Dio? dio}) : _dio = dio ?? AppConfig.dio;

  final Dio _dio;

  static const _mockDelay = Duration(milliseconds: 600);

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(_mockDelay);
      return UserModel(id: 'mock-user', email: email, name: _nameFromEmail(email));
    }
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return UserModel.fromJson(response.data!);
  }

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(_mockDelay);
      return UserModel(id: 'mock-user', email: email, name: name);
    }
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/signup',
      data: {'name': name, 'email': email, 'password': password},
    );
    return UserModel.fromJson(response.data!);
  }

  Future<void> forgotPassword({required String email}) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(_mockDelay);
      return;
    }
    await _dio.post<void>('/auth/forgot-password', data: {'email': email});
  }

  Future<void> logout() async {
    if (AppConfig.useMockData) return;
    await _dio.post<void>('/auth/logout');
  }

  Future<UserModel?> getCurrentUser() async {
    // No persisted session in mock mode → always start unauthenticated so the
    // onboarding flow runs on every launch.
    if (AppConfig.useMockData) return null;
    final response = await _dio.get<Map<String, dynamic>>('/auth/me');
    final data = response.data;
    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  /// Derives a display name from the local part of an email (mock only).
  String _nameFromEmail(String email) {
    final local = email.split('@').first.replaceAll(RegExp(r'[._-]+'), ' ').trim();
    if (local.isEmpty) return 'there';
    return local
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

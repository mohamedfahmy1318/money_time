import 'package:dio/dio.dart';

import 'package:mony_time/src/config/app_config.dart';
import 'package:mony_time/src/features/auth/data/models/user_model.dart';

/// Raw API calls for the auth feature.
///
/// Throws on failure — error mapping happens in the repository via `runTask`.
class AuthRemoteDataSource {
  AuthRemoteDataSource({Dio? dio}) : _dio = dio ?? AppConfig.dio;

  final Dio _dio;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
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
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/signup',
      data: {'name': name, 'email': email, 'password': password},
    );
    return UserModel.fromJson(response.data!);
  }

  Future<void> forgotPassword({required String email}) async {
    await _dio.post<void>('/auth/forgot-password', data: {'email': email});
  }

  Future<void> logout() async {
    await _dio.post<void>('/auth/logout');
  }

  Future<UserModel?> getCurrentUser() async {
    final response = await _dio.get<Map<String, dynamic>>('/auth/me');
    final data = response.data;
    if (data == null) return null;
    return UserModel.fromJson(data);
  }
}

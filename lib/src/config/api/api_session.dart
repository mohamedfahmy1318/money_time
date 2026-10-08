import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import 'package:mony_time/src/utils/logger.dart';
import 'package:mony_time/src/utils/platform_info.dart';

/// Identity and credentials sent with every Money Time API request.
///
/// * A random device id, created once per install and kept across logouts:
///   the server binds one session per device to it (`X-Device-Id`).
/// * The JWT pair — a 15-minute access token and a 60-day refresh token that
///   rotates on every refresh — kept in secure storage (Keychain / Keystore)
///   and mirrored in memory for the interceptor.
/// * The UI language (`Accept-Language`), kept in sync by `App`.
///
/// [onSignedOut] fires when the server ends the session (refresh rejected,
/// `UNAUTHENTICATED`) so the app-wide session state can follow.
class ApiSession {
  ApiSession._();
  static final ApiSession instance = ApiSession._();

  static const _deviceIdKey = 'api.device_id';
  static const _accessKey = 'api.access_token';
  static const _refreshKey = 'api.refresh_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final StreamController<void> _signedOut = StreamController<void>.broadcast();

  String deviceId = '';
  /// `version+buildNumber`; empty when unknown (the server then skips its
  /// minimum-version check instead of failing it).
  String appVersion = '';
  String language = 'ar';
  String? _accessToken;
  String? _refreshToken;

  String get platform => PlatformInfo.isIOS ? 'ios' : 'android';
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  /// A refresh token is held — the user is signed in on this device.
  bool get hasSession => _refreshToken != null;

  Stream<void> get onSignedOut => _signedOut.stream;

  Future<void> init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = '${info.version}+${info.buildNumber}';
    } catch (e) {
      AppLogger.warning('Package info unavailable: $e');
    }

    deviceId = await _read(_deviceIdKey) ?? '';
    if (deviceId.isEmpty) {
      deviceId = const Uuid().v4();
      await _write(_deviceIdKey, deviceId);
    }
    _accessToken = await _read(_accessKey);
    _refreshToken = await _read(_refreshKey);
  }

  /// Stores the pair from login, signup or refresh. The refresh token
  /// rotates on every refresh, so both are always overwritten together.
  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    _accessToken = access;
    _refreshToken = refresh;
    await _write(_accessKey, access);
    await _write(_refreshKey, refresh);
  }

  /// Local sign-out. The device id stays — it identifies the install.
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _delete(_accessKey);
    await _delete(_refreshKey);
  }

  /// The server ended the session: drop the tokens and tell the app.
  Future<void> endSession() async {
    if (!hasSession) return;
    await clearTokens();
    _signedOut.add(null);
  }

  // Storage errors (e.g. a Keystore reset after a backup restore) must not
  // crash startup — a missing value just means "signed out".
  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      AppLogger.warning('Secure storage read failed for $key: $e');
      return null;
    }
  }

  Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      AppLogger.error('Secure storage write failed for $key: $e');
    }
  }

  Future<void> _delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      AppLogger.warning('Secure storage delete failed for $key: $e');
    }
  }
}

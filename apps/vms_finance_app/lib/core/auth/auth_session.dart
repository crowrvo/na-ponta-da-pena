import 'dart:async';
import 'dart:convert';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../sync/entry_sync_api.dart';
import 'auth_configuration.dart';

enum AuthSessionStatus { loading, unauthenticated, authenticated, failure }

abstract interface class AuthenticationSession
    implements AccessTokenProvider, Listenable {
  AuthSessionStatus get status;
  String? get userLabel;
  String? get errorMessage;
  Future<void> initialize();
  Future<void> login();
  Future<void> logout();
}

class Auth0AuthenticationSession extends ChangeNotifier
    implements AuthenticationSession {
  Auth0AuthenticationSession({
    required AuthConfiguration configuration,
    required FlutterSecureStorage secureStorage,
    Dio? tokenClient,
  }) : _configuration = configuration,
       _auth0 = Auth0(configuration.domain, configuration.clientId),
       _secureStorage = secureStorage,
       _tokenClient = tokenClient ?? Dio();

  static const _windowsCredentialsKey = 'auth0_windows_credentials_v1';
  static const _scopes = {'openid', 'profile', 'email', 'offline_access'};

  final AuthConfiguration _configuration;
  final Auth0 _auth0;
  final FlutterSecureStorage _secureStorage;
  final Dio _tokenClient;
  StreamSubscription<Credentials>? _recoveredCredentialsSubscription;

  @override
  AuthSessionStatus status = AuthSessionStatus.loading;

  @override
  String? userLabel;

  @override
  String? errorMessage;

  bool get _isWindows => defaultTargetPlatform == TargetPlatform.windows;
  String? get _mobileScheme => _configuration.callbackScheme.trim().isEmpty
      ? null
      : _configuration.callbackScheme;

  @override
  Future<void> initialize() async {
    if (!_configuration.isConfigured) {
      _setFailure(_configuration.validationError!);
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      _recoveredCredentialsSubscription = _auth0
          .webAuthentication(scheme: _mobileScheme)
          .onCredentialsRecovered
          .listen(_acceptMobileCredentials);
    }
    try {
      if (_isWindows) {
        final stored = await _readWindowsCredentials();
        if (stored == null) {
          _setUnauthenticated();
          return;
        }
        userLabel = stored.userLabel;
        status = AuthSessionStatus.authenticated;
        notifyListeners();
        await readAccessToken();
        return;
      }
      final credentials = await _auth0.credentialsManager.credentials();
      _acceptMobileCredentials(credentials);
    } on CredentialsManagerException {
      _setUnauthenticated();
    } catch (_) {
      _setFailure('Não foi possível restaurar a sessão com segurança.');
    }
  }

  @override
  Future<void> login() async {
    status = AuthSessionStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      late final Credentials credentials;
      if (_isWindows) {
        credentials = await _auth0.windowsWebAuthentication().login(
          appCustomURL: _configuration.windowsCallbackUrl,
          audience: _configuration.audience,
          scopes: _scopes,
        );
        _requireRefreshToken(credentials);
        await _writeWindowsCredentials(
          _WindowsCredentials.fromAuth0(credentials),
        );
      } else {
        credentials = await _auth0
            .webAuthentication(scheme: _mobileScheme)
            .login(audience: _configuration.audience, scopes: _scopes);
        try {
          _requireRefreshToken(credentials);
        } catch (_) {
          await _auth0.credentialsManager.clearAll();
          rethrow;
        }
      }
      _acceptCredentials(credentials);
    } on WebAuthenticationException catch (error) {
      _setFailure(error.message);
    } catch (_) {
      _setFailure('Não foi possível concluir o login.');
    }
  }

  @override
  Future<void> logout() async {
    status = AuthSessionStatus.loading;
    errorMessage = null;
    notifyListeners();
    String? failure;
    try {
      if (_isWindows) {
        await _auth0.windowsWebAuthentication().logout(
          appCustomURL: _configuration.windowsCallbackUrl,
        );
      } else {
        await _auth0.webAuthentication(scheme: _mobileScheme).logout();
      }
    } catch (_) {
      failure =
          'A sessão remota pode continuar ativa, mas os tokens locais foram removidos.';
    } finally {
      if (_isWindows) {
        await _secureStorage.delete(key: _windowsCredentialsKey);
      } else {
        await _auth0.credentialsManager.clearAll();
      }
      userLabel = null;
      status = failure == null
          ? AuthSessionStatus.unauthenticated
          : AuthSessionStatus.failure;
      errorMessage = failure;
      notifyListeners();
    }
  }

  @override
  Future<String?> readAccessToken() async {
    try {
      if (_isWindows) {
        final stored = await _readWindowsCredentials();
        if (stored == null) {
          _setUnauthenticated();
          return null;
        }
        if (stored.expiresAt.isAfter(
          DateTime.now().toUtc().add(const Duration(minutes: 1)),
        )) {
          return stored.accessToken;
        }
        final refreshed = await _refreshWindowsCredentials(stored);
        _acceptWindowsCredentials(refreshed);
        return refreshed.accessToken;
      }
      final credentials = await _auth0.credentialsManager.credentials(
        minTtl: 60,
      );
      _acceptMobileCredentials(credentials);
      return credentials.accessToken;
    } catch (_) {
      _setUnauthenticated();
      return null;
    }
  }

  Future<_WindowsCredentials> _refreshWindowsCredentials(
    _WindowsCredentials stored,
  ) async {
    final refreshToken = stored.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('The Windows session has no refresh token.');
    }
    final response = await _tokenClient.post<Map<String, dynamic>>(
      'https://${_configuration.domain}/oauth/token',
      data: {
        'grant_type': 'refresh_token',
        'client_id': _configuration.clientId,
        'refresh_token': refreshToken,
      },
      options: Options(contentType: Headers.jsonContentType),
    );
    final data = response.data;
    final accessToken = data?['access_token'];
    final expiresIn = data?['expires_in'];
    if (accessToken is! String || expiresIn is! num || expiresIn <= 0) {
      throw const FormatException('Invalid token refresh response.');
    }
    final refreshed = stored.copyWith(
      accessToken: accessToken,
      refreshToken: data?['refresh_token'] is String
          ? data!['refresh_token'] as String
          : refreshToken,
      expiresAt: DateTime.now().toUtc().add(
        Duration(seconds: expiresIn.toInt()),
      ),
    );
    await _writeWindowsCredentials(refreshed);
    return refreshed;
  }

  void _acceptMobileCredentials(Credentials credentials) =>
      _acceptCredentials(credentials);

  void _requireRefreshToken(Credentials credentials) {
    if (credentials.refreshToken?.isEmpty ?? true) {
      throw StateError(
        'Auth0 did not issue a refresh token for the offline_access scope.',
      );
    }
  }

  void _acceptCredentials(Credentials credentials) {
    userLabel = credentials.user.name ?? credentials.user.email;
    status = AuthSessionStatus.authenticated;
    errorMessage = null;
    notifyListeners();
  }

  void _acceptWindowsCredentials(_WindowsCredentials credentials) {
    userLabel = credentials.userLabel;
    status = AuthSessionStatus.authenticated;
    errorMessage = null;
    notifyListeners();
  }

  void _setUnauthenticated() {
    userLabel = null;
    status = AuthSessionStatus.unauthenticated;
    errorMessage = null;
    notifyListeners();
  }

  void _setFailure(String message) {
    status = AuthSessionStatus.failure;
    errorMessage = message;
    notifyListeners();
  }

  Future<_WindowsCredentials?> _readWindowsCredentials() async {
    final raw = await _secureStorage.read(key: _windowsCredentialsKey);
    if (raw == null) return null;
    return _WindowsCredentials.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> _writeWindowsCredentials(_WindowsCredentials credentials) =>
      _secureStorage.write(
        key: _windowsCredentialsKey,
        value: jsonEncode(credentials.toJson()),
      );

  @override
  void dispose() {
    _recoveredCredentialsSubscription?.cancel();
    super.dispose();
  }
}

class _WindowsCredentials {
  const _WindowsCredentials({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.userLabel,
  });

  factory _WindowsCredentials.fromAuth0(Credentials credentials) =>
      _WindowsCredentials(
        accessToken: credentials.accessToken,
        refreshToken: credentials.refreshToken,
        expiresAt: credentials.expiresAt.toUtc(),
        userLabel: credentials.user.name ?? credentials.user.email,
      );

  factory _WindowsCredentials.fromJson(Map<String, dynamic> json) =>
      _WindowsCredentials(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String?,
        expiresAt: DateTime.parse(json['expiresAt'] as String).toUtc(),
        userLabel: json['userLabel'] as String?,
      );

  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;
  final String? userLabel;

  _WindowsCredentials copyWith({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) => _WindowsCredentials(
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresAt: expiresAt,
    userLabel: userLabel,
  );

  Map<String, Object?> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'userLabel': userLabel,
  };
}

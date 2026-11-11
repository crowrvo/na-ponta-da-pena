import 'package:flutter/foundation.dart';

class AuthConfiguration {
  const AuthConfiguration({
    required this.domain,
    required this.clientId,
    required this.audience,
    required this.callbackScheme,
    required this.windowsCallbackUrl,
  });

  factory AuthConfiguration.fromEnvironment() => AuthConfiguration(
    domain: const String.fromEnvironment('VMS_AUTH0_DOMAIN'),
    clientId: const String.fromEnvironment('VMS_AUTH0_CLIENT_ID'),
    audience: const String.fromEnvironment('VMS_AUTH0_AUDIENCE'),
    callbackScheme: const String.fromEnvironment('VMS_AUTH0_SCHEME'),
    windowsCallbackUrl: const String.fromEnvironment(
      'VMS_AUTH0_WINDOWS_CALLBACK_URL',
    ),
  );

  final String domain;
  final String clientId;
  final String audience;
  final String callbackScheme;
  final String windowsCallbackUrl;

  bool get isConfigured => validationError == null;

  String? get validationError {
    if ([domain, clientId, audience].any((value) => value.trim().isEmpty)) {
      return 'Auth0 domain, client ID and audience must be provided together.';
    }
    final authority = Uri.tryParse('https://${domain.trim()}');
    if (authority == null ||
        authority.scheme != 'https' ||
        authority.host != domain.trim() ||
        authority.path.isNotEmpty ||
        authority.hasQuery ||
        authority.hasFragment ||
        authority.userInfo.isNotEmpty) {
      return 'Auth0 domain must be a hostname without scheme, path or credentials.';
    }
    final audienceUri = Uri.tryParse(audience.trim());
    if (audienceUri == null ||
        audienceUri.scheme != 'https' ||
        audienceUri.host.isEmpty ||
        audienceUri.userInfo.isNotEmpty ||
        audienceUri.hasQuery ||
        audienceUri.hasFragment) {
      return 'Auth0 audience must be an HTTPS URI without credentials, query or fragment.';
    }
    if (defaultTargetPlatform == TargetPlatform.android &&
        !_isValidScheme(callbackScheme)) {
      return 'Android requires VMS_AUTH0_SCHEME.';
    }
    if (defaultTargetPlatform == TargetPlatform.windows) {
      final callback = Uri.tryParse(windowsCallbackUrl.trim());
      if (callback == null ||
          !_isValidScheme(callback.scheme) ||
          callback.host != 'callback' ||
          callback.path.isNotEmpty ||
          callback.hasQuery ||
          callback.hasFragment ||
          callback.userInfo.isNotEmpty) {
        return 'Windows requires a custom callback URL ending in ://callback.';
      }
    }
    return null;
  }

  static bool _isValidScheme(String value) => RegExp(
    r'^[a-z][a-z0-9+.-]*$',
    caseSensitive: false,
  ).hasMatch(value.trim());
}

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vms_finance_app/core/auth/auth_configuration.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('accepts external Android Auth0 settings without secrets', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const configuration = AuthConfiguration(
      domain: 'tenant.example.auth0.com',
      clientId: 'public-client-id',
      audience: 'https://api.example.com',
      callbackScheme: 'vmsfinance',
      windowsCallbackUrl: '',
    );

    expect(configuration.isConfigured, isTrue);
  });

  test('rejects an insecure authority or audience', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    const configuration = AuthConfiguration(
      domain: 'https://tenant.example.auth0.com/path',
      clientId: 'public-client-id',
      audience: 'http://api.example.com?token=value',
      callbackScheme: '',
      windowsCallbackUrl: '',
    );

    expect(configuration.isConfigured, isFalse);
  });

  test('requires the externally supplied Windows callback URL', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    const configuration = AuthConfiguration(
      domain: 'tenant.example.auth0.com',
      clientId: 'public-client-id',
      audience: 'https://api.example.com',
      callbackScheme: '',
      windowsCallbackUrl: '',
    );

    expect(configuration.validationError, contains('Windows'));
  });
}

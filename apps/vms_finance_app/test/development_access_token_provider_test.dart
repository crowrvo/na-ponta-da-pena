import 'package:flutter_test/flutter_test.dart';
import 'package:vms_finance_app/core/sync/development_access_token_provider.dart';
import 'package:vms_finance_app/core/sync/entry_sync_api.dart';

void main() {
  test('uses development token only for non-release loopback API', () async {
    const secure = _FixedTokenProvider('secure-token');

    final provider = selectAccessTokenProvider(
      releaseMode: false,
      apiEndpoint: Uri.parse('http://127.0.0.1:5080'),
      developmentToken: 'local-token',
      secureProvider: secure,
    );

    expect(await provider.readAccessToken(), 'local-token');
  });

  test('release builds ignore development token', () async {
    const secure = _FixedTokenProvider('secure-token');

    final provider = selectAccessTokenProvider(
      releaseMode: true,
      apiEndpoint: Uri.parse('http://127.0.0.1:5080'),
      developmentToken: 'local-token',
      secureProvider: secure,
    );

    expect(identical(provider, secure), isTrue);
  });

  test('remote APIs ignore development token', () async {
    const secure = _FixedTokenProvider('secure-token');

    final provider = selectAccessTokenProvider(
      releaseMode: false,
      apiEndpoint: Uri.parse('https://api.example.com'),
      developmentToken: 'local-token',
      secureProvider: secure,
    );

    expect(identical(provider, secure), isTrue);
  });
}

class _FixedTokenProvider implements AccessTokenProvider {
  const _FixedTokenProvider(this.token);

  final String token;

  @override
  Future<String?> readAccessToken() async => token;
}

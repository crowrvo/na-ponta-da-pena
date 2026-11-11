import 'entry_sync_api.dart';

class DevelopmentAccessTokenProvider implements AccessTokenProvider {
  const DevelopmentAccessTokenProvider(this._token);

  final String _token;

  @override
  Future<String?> readAccessToken() async => _token;
}

AccessTokenProvider selectAccessTokenProvider({
  required bool releaseMode,
  required Uri? apiEndpoint,
  required String developmentToken,
  required AccessTokenProvider secureProvider,
}) {
  final isLoopback =
      apiEndpoint != null &&
      (apiEndpoint.host == 'localhost' || apiEndpoint.host == '127.0.0.1');
  if (!releaseMode && isLoopback && developmentToken.trim().isNotEmpty) {
    return DevelopmentAccessTokenProvider(developmentToken);
  }
  return secureProvider;
}

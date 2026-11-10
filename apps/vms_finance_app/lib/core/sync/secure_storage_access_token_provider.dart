import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'entry_sync_api.dart';

class SecureStorageAccessTokenProvider implements AccessTokenProvider {
  const SecureStorageAccessTokenProvider(
    this._storage, {
    this.storageKey = 'oidc_access_token',
  });

  final FlutterSecureStorage _storage;
  final String storageKey;

  @override
  Future<String?> readAccessToken() => _storage.read(key: storageKey);
}

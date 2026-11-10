Uri? parseVmsApiBaseUrl(String value, {required bool allowLocalHttp}) {
  final normalized = value.trim();
  if (normalized.isEmpty) return null;

  final uri = Uri.tryParse(normalized);
  if (uri == null ||
      !uri.isAbsolute ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      (uri.path.isNotEmpty && uri.path != '/')) {
    return null;
  }

  final secure = uri.scheme.toLowerCase() == 'https';
  final localDevelopment =
      allowLocalHttp &&
      uri.scheme.toLowerCase() == 'http' &&
      (uri.host.toLowerCase() == 'localhost' || uri.host == '127.0.0.1');
  if (!secure && !localDevelopment) return null;

  return uri.replace(
    scheme: uri.scheme.toLowerCase(),
    host: uri.host.toLowerCase(),
    path: '',
  );
}

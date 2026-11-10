import 'package:flutter_test/flutter_test.dart';
import 'package:vms_finance_app/core/config/api_endpoint.dart';

void main() {
  test('accepts and normalizes an HTTPS origin', () {
    final endpoint = parseVmsApiBaseUrl(
      ' HTTPS://API.CROWRVO.COM.BR/ ',
      allowLocalHttp: false,
    );

    expect(endpoint.toString(), 'https://api.crowrvo.com.br');
  });

  test('allows local HTTP only when development explicitly permits it', () {
    expect(
      parseVmsApiBaseUrl(
        'http://127.0.0.1:5080',
        allowLocalHttp: true,
      ).toString(),
      'http://127.0.0.1:5080',
    );
    expect(
      parseVmsApiBaseUrl('http://localhost:5080', allowLocalHttp: false),
      isNull,
    );
  });

  test('rejects insecure remote and ambiguous URLs', () {
    for (final value in [
      'http://api.crowrvo.com.br',
      'https://user:secret@api.crowrvo.com.br',
      'https://api.crowrvo.com.br/base',
      'https://api.crowrvo.com.br?token=value',
      'not-a-url',
      '',
    ]) {
      expect(
        parseVmsApiBaseUrl(value, allowLocalHttp: true),
        isNull,
        reason: value,
      );
    }
  });
}

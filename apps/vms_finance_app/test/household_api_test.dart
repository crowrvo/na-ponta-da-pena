import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vms_finance_app/features/households/data/household_api.dart';
import 'package:vms_finance_app/features/households/domain/household.dart';

void main() {
  test(
    'uses bearer auth and maps list, create and invitation responses',
    () async {
      final adapter = QueueAdapter([
        ResponseSpec(200, [
          {
            'id': '11111111-1111-4111-8111-111111111111',
            'name': 'Casa',
            'role': 'owner',
          },
        ]),
        ResponseSpec(201, {
          'id': '22222222-2222-4222-8222-222222222222',
          'name': 'Nova',
          'role': 'owner',
        }),
        ResponseSpec(200, {
          'householdId': '33333333-3333-4333-8333-333333333333',
          'householdName': 'Convidada',
          'role': 'member',
        }),
      ]);
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = adapter;
      final api = DioHouseholdApi(dio);

      final listed = await api.listHouseholds('access-token');
      final created = await api.createHousehold('access-token', 'Nova');
      final accepted = await api.acceptInvitation(
        'access-token',
        'invitation-secret',
      );

      expect(listed.single.role, HouseholdRole.owner);
      expect(created.name, 'Nova');
      expect(accepted.role, HouseholdRole.member);
      expect(
        adapter.requests.map((request) => request.headers['Authorization']),
        everyElement('Bearer access-token'),
      );
      expect(adapter.requests[0].path, '/api/households');
      expect(adapter.requests[1].data, {'name': 'Nova'});
      expect(adapter.requests[2].data, {'token': 'invitation-secret'});
    },
  );

  test('maps unauthorized responses to the authentication exception', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = QueueAdapter([
        const ResponseSpec(401, {'title': 'Unauthorized'}),
      ]);

    await expectLater(
      DioHouseholdApi(dio).listHouseholds('expired-token'),
      throwsA(isA<HouseholdAuthenticationException>()),
    );
  });
}

class ResponseSpec {
  const ResponseSpec(this.statusCode, this.body);

  final int statusCode;
  final Object body;
}

class QueueAdapter implements HttpClientAdapter {
  QueueAdapter(this.responses);

  final List<ResponseSpec> responses;
  final List<RequestOptions> requests = [];
  var _index = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = responses[_index++];
    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

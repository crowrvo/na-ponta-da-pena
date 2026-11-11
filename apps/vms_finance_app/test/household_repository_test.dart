import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vms_finance_app/core/database/app_database.dart';
import 'package:vms_finance_app/core/sync/entry_sync_api.dart';
import 'package:vms_finance_app/features/households/data/household_api.dart';
import 'package:vms_finance_app/features/households/data/household_repository.dart';
import 'package:vms_finance_app/features/households/domain/household.dart';

void main() {
  const first = HouseholdSummary(
    id: '11111111-1111-4111-8111-111111111111',
    name: 'Casa',
    role: HouseholdRole.owner,
  );
  const second = HouseholdSummary(
    id: '22222222-2222-4222-8222-222222222222',
    name: 'Pais',
    role: HouseholdRole.member,
  );
  late AppDatabase database;
  late FakeHouseholdApi api;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    api = FakeHouseholdApi([first, second]);
  });

  tearDown(() => database.close());

  HouseholdRepository repository({String? token = 'access-token'}) =>
      HouseholdRepository(
        database: database,
        api: api,
        tokenProvider: FixedTokenProvider(token),
        clock: () => DateTime.utc(2026, 11, 10, 22),
      );

  test(
    'refresh caches households and keeps the active selection offline',
    () async {
      final store = repository();

      final online = await store.refresh(online: true);
      await store.selectHousehold(second.id);
      final offline = await store.refresh(online: false);

      expect(online.source, HouseholdRefreshSource.remote);
      expect(online.households, [first, second]);
      expect(online.activeHouseholdId, first.id);
      expect(offline.source, HouseholdRefreshSource.offlineCache);
      expect(offline.households, [first, second]);
      expect(offline.activeHouseholdId, second.id);
      expect(api.listTokens, ['access-token']);
    },
  );

  test(
    'refresh without token returns cached data and requires authentication',
    () async {
      await repository().refresh(online: true);

      final result = await repository(token: null).refresh(online: true);

      expect(result.source, HouseholdRefreshSource.authenticationRequired);
      expect(result.households, [first, second]);
      expect(api.listTokens, hasLength(1));
    },
  );

  test('transport failure safely falls back to the local cache', () async {
    final store = repository();
    await store.refresh(online: true);
    api.error = const HouseholdTransportException();

    final result = await store.refresh(online: true);

    expect(result.source, HouseholdRefreshSource.offlineCache);
    expect(result.households, [first, second]);
  });

  test(
    'create and accept invitation upsert and select the returned family',
    () async {
      final store = repository();
      api.created = const HouseholdSummary(
        id: '33333333-3333-4333-8333-333333333333',
        name: 'Nova',
        role: HouseholdRole.owner,
      );
      api.accepted = const HouseholdSummary(
        id: '44444444-4444-4444-8444-444444444444',
        name: 'Convidada',
        role: HouseholdRole.member,
      );

      final created = await store.createHousehold('  Nova  ');
      final accepted = await store.acceptInvitation('  invitation-secret  ');

      expect(created.activeHouseholdId, api.created.id);
      expect(accepted.activeHouseholdId, api.accepted.id);
      expect(api.createdName, 'Nova');
      expect(api.invitationToken, 'invitation-secret');
      expect(
        accepted.households,
        containsAll(<HouseholdSummary>[api.created, api.accepted]),
      );
    },
  );

  test('selection rejects an unknown household id', () async {
    await expectLater(
      repository().selectHousehold('missing'),
      throwsArgumentError,
    );
  });
}

class FixedTokenProvider implements AccessTokenProvider {
  const FixedTokenProvider(this.token);

  final String? token;

  @override
  Future<String?> readAccessToken() async => token;
}

class FakeHouseholdApi implements HouseholdApi {
  FakeHouseholdApi(this.households);

  List<HouseholdSummary> households;
  Object? error;
  HouseholdSummary created = const HouseholdSummary(
    id: '33333333-3333-4333-8333-333333333333',
    name: 'Created',
    role: HouseholdRole.owner,
  );
  HouseholdSummary accepted = const HouseholdSummary(
    id: '44444444-4444-4444-8444-444444444444',
    name: 'Accepted',
    role: HouseholdRole.member,
  );
  String? createdName;
  String? invitationToken;
  final List<String> listTokens = [];

  void _throwIfNeeded() {
    if (error case final error?) throw error;
  }

  @override
  Future<List<HouseholdSummary>> listHouseholds(String accessToken) async {
    listTokens.add(accessToken);
    _throwIfNeeded();
    return households;
  }

  @override
  Future<HouseholdSummary> createHousehold(
    String accessToken,
    String name,
  ) async {
    _throwIfNeeded();
    createdName = name;
    return created;
  }

  @override
  Future<HouseholdSummary> acceptInvitation(
    String accessToken,
    String invitationToken,
  ) async {
    _throwIfNeeded();
    this.invitationToken = invitationToken;
    return accepted;
  }
}

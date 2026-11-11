import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vms_finance_app/core/sync/connectivity_monitor.dart';
import 'package:vms_finance_app/features/households/data/household_repository.dart';
import 'package:vms_finance_app/features/households/domain/household.dart';
import 'package:vms_finance_app/features/households/presentation/household_cubit.dart';
import 'package:vms_finance_app/features/households/presentation/household_state.dart';

void main() {
  const household = HouseholdSummary(
    id: '11111111-1111-4111-8111-111111111111',
    name: 'Casa',
    role: HouseholdRole.owner,
  );

  test('initialize exposes cached households as offline', () async {
    final store = FakeHouseholdStore(
      refreshResult: const HouseholdRefreshResult(
        households: [household],
        source: HouseholdRefreshSource.offlineCache,
        activeHouseholdId: '11111111-1111-4111-8111-111111111111',
      ),
    );
    final connectivity = FakeConnectivity(false);
    final cubit = HouseholdCubit(repository: store, connectivity: connectivity);

    await cubit.initialize();

    expect(cubit.state.status, HouseholdStatus.offline);
    expect(cubit.state.activeHousehold, household);
    expect(store.lastOnline, isFalse);
    await cubit.close();
    await connectivity.close();
  });

  test('reconnection refreshes remote households and selection', () async {
    final store = FakeHouseholdStore(
      refreshResult: const HouseholdRefreshResult(
        households: [],
        source: HouseholdRefreshSource.offlineCache,
      ),
    );
    final connectivity = FakeConnectivity(false);
    final cubit = HouseholdCubit(repository: store, connectivity: connectivity);
    await cubit.initialize();
    store.refreshResult = const HouseholdRefreshResult(
      households: [household],
      source: HouseholdRefreshSource.remote,
      activeHouseholdId: '11111111-1111-4111-8111-111111111111',
    );

    connectivity.emit(true);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, HouseholdStatus.ready);
    expect(cubit.state.activeHouseholdId, household.id);
    expect(store.lastOnline, isTrue);
    await cubit.close();
    await connectivity.close();
  });

  test('create is blocked offline without calling the repository', () async {
    final store = FakeHouseholdStore(
      refreshResult: const HouseholdRefreshResult(
        households: [],
        source: HouseholdRefreshSource.offlineCache,
      ),
    );
    final connectivity = FakeConnectivity(false);
    final cubit = HouseholdCubit(repository: store, connectivity: connectivity);
    await cubit.initialize();

    final created = await cubit.createHousehold('Casa');

    expect(created, isFalse);
    expect(store.createdNames, isEmpty);
    expect(cubit.state.status, HouseholdStatus.failure);
    expect(cubit.state.errorMessage, contains('internet'));
    await cubit.close();
    await connectivity.close();
  });

  test('create selects the new family while online', () async {
    final store = FakeHouseholdStore(
      refreshResult: const HouseholdRefreshResult(
        households: [],
        source: HouseholdRefreshSource.remote,
      ),
      createResult: const HouseholdRefreshResult(
        households: [household],
        source: HouseholdRefreshSource.remote,
        activeHouseholdId: '11111111-1111-4111-8111-111111111111',
      ),
    );
    final connectivity = FakeConnectivity(true);
    final cubit = HouseholdCubit(repository: store, connectivity: connectivity);
    await cubit.initialize();

    final created = await cubit.createHousehold('Casa');

    expect(created, isTrue);
    expect(cubit.state.status, HouseholdStatus.ready);
    expect(cubit.state.activeHouseholdId, household.id);
    await cubit.close();
    await connectivity.close();
  });

  test(
    'missing authentication is represented without exposing an error',
    () async {
      final store = FakeHouseholdStore(
        refreshResult: const HouseholdRefreshResult(
          households: [],
          source: HouseholdRefreshSource.authenticationRequired,
        ),
      );
      final connectivity = FakeConnectivity(true);
      final cubit = HouseholdCubit(
        repository: store,
        connectivity: connectivity,
      );

      await cubit.initialize();

      expect(cubit.state.status, HouseholdStatus.authenticationRequired);
      expect(cubit.state.errorMessage, isNull);
      await cubit.close();
      await connectivity.close();
    },
  );
}

class FakeConnectivity implements ConnectivityMonitor {
  FakeConnectivity(this.online);

  bool online;
  final StreamController<bool> _controller = StreamController<bool>.broadcast(
    sync: true,
  );

  @override
  Future<bool> get isOnline async => online;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  void emit(bool value) {
    online = value;
    _controller.add(value);
  }

  Future<void> close() => _controller.close();
}

class FakeHouseholdStore implements HouseholdStore {
  FakeHouseholdStore({required this.refreshResult, this.createResult});

  HouseholdRefreshResult refreshResult;
  HouseholdRefreshResult? createResult;
  bool? lastOnline;
  final List<String> createdNames = [];

  @override
  Future<HouseholdRefreshResult> refresh({required bool online}) async {
    lastOnline = online;
    return refreshResult;
  }

  @override
  Future<HouseholdRefreshResult> createHousehold(String name) async {
    createdNames.add(name);
    return createResult ?? refreshResult;
  }

  @override
  Future<HouseholdRefreshResult> acceptInvitation(
    String invitationToken,
  ) async => createResult ?? refreshResult;

  @override
  Future<HouseholdRefreshResult> selectHousehold(String householdId) async =>
      refreshResult;
}

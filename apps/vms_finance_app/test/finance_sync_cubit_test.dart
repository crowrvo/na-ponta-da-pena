import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vms_finance_app/core/sync/connectivity_monitor.dart';
import 'package:vms_finance_app/core/sync/finance_sync_service.dart';
import 'package:vms_finance_app/features/sync/presentation/finance_sync_cubit.dart';
import 'package:vms_finance_app/features/sync/presentation/finance_sync_state.dart';

void main() {
  test('reports that API configuration is required without a runner', () async {
    final connectivity = FakeConnectivityMonitor(true);
    final cubit = FinanceSyncCubit(connectivity: connectivity);

    await cubit.initialize();

    expect(cubit.state.status, FinanceSyncStatus.notConfigured);
    await cubit.close();
    await connectivity.close();
  });

  test('stays offline without calling the sync runner', () async {
    final connectivity = FakeConnectivityMonitor(false);
    final runner = FakeSyncRunner(const SyncRunResult(SyncRunStatus.completed));
    final cubit = FinanceSyncCubit(connectivity: connectivity, runner: runner);

    await cubit.initialize();

    expect(cubit.state.status, FinanceSyncStatus.offline);
    expect(runner.calls, 0);
    await cubit.close();
    await connectivity.close();
  });

  test('exposes authentication required after an automatic sync', () async {
    final connectivity = FakeConnectivityMonitor(true);
    final runner = FakeSyncRunner(
      const SyncRunResult(SyncRunStatus.authenticationRequired),
    );
    final cubit = FinanceSyncCubit(connectivity: connectivity, runner: runner);

    await cubit.initialize();

    expect(cubit.state.status, FinanceSyncStatus.authenticationRequired);
    expect(runner.calls, 1);
    await cubit.close();
    await connectivity.close();
  });

  test('syncs when connectivity is restored', () async {
    final connectivity = FakeConnectivityMonitor(false);
    final runner = FakeSyncRunner(
      const SyncRunResult(SyncRunStatus.completed, synced: 2),
    );
    final cubit = FinanceSyncCubit(connectivity: connectivity, runner: runner);
    await cubit.initialize();

    connectivity.emit(true);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, FinanceSyncStatus.synchronized);
    expect(cubit.state.synced, 2);
    expect(runner.calls, 1);
    await cubit.close();
    await connectivity.close();
  });
}

class FakeConnectivityMonitor implements ConnectivityMonitor {
  FakeConnectivityMonitor(this.online);

  bool online;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

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

class FakeSyncRunner implements FinanceSyncRunner {
  FakeSyncRunner(this.result);

  final SyncRunResult result;
  int calls = 0;

  @override
  Future<SyncRunResult> syncPending({int limit = 50}) async {
    calls++;
    return result;
  }
}

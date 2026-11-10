import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/sync/connectivity_monitor.dart';
import '../../../core/sync/finance_sync_service.dart';
import 'finance_sync_state.dart';

class FinanceSyncCubit extends Cubit<FinanceSyncState> {
  FinanceSyncCubit({
    required ConnectivityMonitor connectivity,
    FinanceSyncRunner? runner,
  }) : _connectivity = connectivity,
       _runner = runner,
       super(const FinanceSyncState());

  final ConnectivityMonitor _connectivity;
  final FinanceSyncRunner? _runner;
  StreamSubscription<bool>? _connectivitySubscription;
  bool _online = false;
  bool _syncing = false;

  Future<void> initialize() async {
    if (_runner == null) {
      _emitIfOpen(
        const FinanceSyncState(status: FinanceSyncStatus.notConfigured),
      );
      return;
    }

    _connectivitySubscription ??= _connectivity.onConnectivityChanged.listen(
      (online) => unawaited(_handleConnectivity(online)),
      onError: (_) => _emitIfOpen(
        const FinanceSyncState(status: FinanceSyncStatus.failure),
      ),
    );
    await _handleConnectivity(await _connectivity.isOnline);
  }

  Future<void> _handleConnectivity(bool online) async {
    _online = online;
    if (!online) {
      _emitIfOpen(
        FinanceSyncState(
          status: FinanceSyncStatus.offline,
          synced: state.synced,
          conflicts: state.conflicts,
        ),
      );
      return;
    }
    await syncNow();
  }

  Future<void> syncNow() async {
    final runner = _runner;
    if (runner == null) {
      _emitIfOpen(
        const FinanceSyncState(status: FinanceSyncStatus.notConfigured),
      );
      return;
    }
    if (!_online) {
      _emitIfOpen(
        FinanceSyncState(
          status: FinanceSyncStatus.offline,
          synced: state.synced,
          conflicts: state.conflicts,
        ),
      );
      return;
    }
    if (_syncing) return;

    _syncing = true;
    _emitIfOpen(
      FinanceSyncState(
        status: FinanceSyncStatus.syncing,
        synced: state.synced,
        conflicts: state.conflicts,
      ),
    );
    try {
      final result = await runner.syncPending();
      switch (result.status) {
        case SyncRunStatus.completed:
        case SyncRunStatus.nothingToDo:
        case SyncRunStatus.alreadyRunning:
          _emitIfOpen(
            FinanceSyncState(
              status: FinanceSyncStatus.synchronized,
              synced: result.synced,
              conflicts: result.conflicts,
            ),
          );
        case SyncRunStatus.authenticationRequired:
          _emitIfOpen(
            FinanceSyncState(
              status: FinanceSyncStatus.authenticationRequired,
              synced: result.synced,
              conflicts: result.conflicts,
            ),
          );
      }
    } on Object {
      _emitIfOpen(
        FinanceSyncState(
          status: FinanceSyncStatus.failure,
          synced: state.synced,
          conflicts: state.conflicts,
        ),
      );
    } finally {
      _syncing = false;
    }
  }

  void _emitIfOpen(FinanceSyncState nextState) {
    if (!isClosed) emit(nextState);
  }

  @override
  Future<void> close() async {
    await _connectivitySubscription?.cancel();
    return super.close();
  }
}

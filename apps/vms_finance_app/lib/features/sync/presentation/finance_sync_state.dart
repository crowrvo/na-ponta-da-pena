enum FinanceSyncStatus {
  initial,
  notConfigured,
  offline,
  syncing,
  synchronized,
  authenticationRequired,
  failure,
}

class FinanceSyncState {
  const FinanceSyncState({
    this.status = FinanceSyncStatus.initial,
    this.synced = 0,
    this.conflicts = 0,
  });

  final FinanceSyncStatus status;
  final int synced;
  final int conflicts;

  bool get canSync =>
      status != FinanceSyncStatus.syncing &&
      status != FinanceSyncStatus.notConfigured &&
      status != FinanceSyncStatus.offline;
}

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/entry_sync_api.dart';
import '../domain/household.dart';
import 'household_api.dart';

enum HouseholdRefreshSource { remote, offlineCache, authenticationRequired }

class HouseholdRefreshResult {
  const HouseholdRefreshResult({
    required this.households,
    required this.source,
    this.activeHouseholdId,
  });

  final List<HouseholdSummary> households;
  final HouseholdRefreshSource source;
  final String? activeHouseholdId;
}

abstract interface class HouseholdStore {
  Future<HouseholdRefreshResult> refresh({required bool online});

  Future<HouseholdRefreshResult> createHousehold(String name);

  Future<HouseholdRefreshResult> acceptInvitation(String invitationToken);

  Future<HouseholdRefreshResult> selectHousehold(String householdId);
}

class HouseholdRepository implements HouseholdStore {
  HouseholdRepository({
    required AppDatabase database,
    required HouseholdApi api,
    required AccessTokenProvider tokenProvider,
    DateTime Function()? clock,
  }) : _database = database,
       _api = api,
       _tokenProvider = tokenProvider,
       _clock = clock ?? DateTime.now;

  final AppDatabase _database;
  final HouseholdApi _api;
  final AccessTokenProvider _tokenProvider;
  final DateTime Function() _clock;

  @override
  Future<HouseholdRefreshResult> refresh({required bool online}) async {
    if (!online) {
      return _cached(HouseholdRefreshSource.offlineCache);
    }

    final token = await _tokenProvider.readAccessToken();
    if (token == null || token.trim().isEmpty) {
      return _cached(HouseholdRefreshSource.authenticationRequired);
    }

    try {
      final households = await _api.listHouseholds(token);
      await _replaceCache(households);
      return _cached(HouseholdRefreshSource.remote);
    } on HouseholdAuthenticationException {
      return _cached(HouseholdRefreshSource.authenticationRequired);
    } on HouseholdTransportException {
      return _cached(HouseholdRefreshSource.offlineCache);
    }
  }

  @override
  Future<HouseholdRefreshResult> createHousehold(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty || normalized.length > 120) {
      throw ArgumentError.value(
        name,
        'name',
        'must contain 1 to 120 characters',
      );
    }
    final token = await _requireToken();
    final household = await _api.createHousehold(token, normalized);
    await _upsertAndSelect(household);
    return _cached(HouseholdRefreshSource.remote);
  }

  @override
  Future<HouseholdRefreshResult> acceptInvitation(
    String invitationToken,
  ) async {
    final normalized = invitationToken.trim();
    if (normalized.isEmpty || normalized.length > 512) {
      throw ArgumentError.value(
        invitationToken,
        'invitationToken',
        'is invalid',
      );
    }
    final token = await _requireToken();
    final household = await _api.acceptInvitation(token, normalized);
    await _upsertAndSelect(household);
    return _cached(HouseholdRefreshSource.remote);
  }

  @override
  Future<HouseholdRefreshResult> selectHousehold(String householdId) async {
    final exists = await (_database.select(
      _database.cachedHouseholds,
    )..where((row) => row.id.equals(householdId))).getSingleOrNull();
    if (exists == null) {
      throw ArgumentError.value(householdId, 'householdId', 'is not cached');
    }
    await _writeSelection(householdId);
    return _cached(HouseholdRefreshSource.remote);
  }

  Future<String> _requireToken() async {
    final token = await _tokenProvider.readAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw const HouseholdAuthenticationException();
    }
    return token;
  }

  Future<void> _replaceCache(List<HouseholdSummary> households) async {
    final current = await _readActiveHouseholdId();
    final now = _clock().toUtc();
    await _database.transaction(() async {
      await _database.delete(_database.cachedHouseholds).go();
      for (final household in households) {
        await _database
            .into(_database.cachedHouseholds)
            .insert(
              CachedHouseholdsCompanion.insert(
                id: household.id,
                name: household.name,
                role: household.role.name,
                refreshedAt: now,
              ),
            );
      }
      final availableIds = households.map((item) => item.id).toSet();
      final selected = availableIds.contains(current)
          ? current
          : households.firstOrNull?.id;
      await _writeSelection(selected);
    });
  }

  Future<void> _upsertAndSelect(HouseholdSummary household) async {
    await _database.transaction(() async {
      await _database
          .into(_database.cachedHouseholds)
          .insertOnConflictUpdate(
            CachedHouseholdsCompanion.insert(
              id: household.id,
              name: household.name,
              role: household.role.name,
              refreshedAt: _clock().toUtc(),
            ),
          );
      await _writeSelection(household.id);
    });
  }

  Future<HouseholdRefreshResult> _cached(HouseholdRefreshSource source) async {
    final rows = await (_database.select(
      _database.cachedHouseholds,
    )..orderBy([(row) => OrderingTerm.asc(row.name)])).get();
    final active = await _readActiveHouseholdId();
    return HouseholdRefreshResult(
      households: rows
          .map(
            (row) => HouseholdSummary(
              id: row.id,
              name: row.name,
              role: HouseholdRole.fromJson(row.role),
            ),
          )
          .toList(growable: false),
      source: source,
      activeHouseholdId: active,
    );
  }

  Future<String?> _readActiveHouseholdId() async {
    final row = await (_database.select(
      _database.householdPreferences,
    )..where((item) => item.id.equals(1))).getSingleOrNull();
    return row?.activeHouseholdId;
  }

  Future<void> _writeSelection(String? householdId) async {
    await _database
        .into(_database.householdPreferences)
        .insertOnConflictUpdate(
          HouseholdPreferencesCompanion.insert(
            id: const Value(1),
            activeHouseholdId: Value(householdId),
          ),
        );
  }
}

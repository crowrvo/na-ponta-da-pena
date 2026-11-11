import '../domain/household.dart';

enum HouseholdStatus {
  initial,
  loading,
  ready,
  empty,
  offline,
  authenticationRequired,
  saving,
  failure,
}

class HouseholdState {
  const HouseholdState({
    this.status = HouseholdStatus.initial,
    this.households = const [],
    this.activeHouseholdId,
    this.errorMessage,
  });

  final HouseholdStatus status;
  final List<HouseholdSummary> households;
  final String? activeHouseholdId;
  final String? errorMessage;

  HouseholdSummary? get activeHousehold => households
      .where((household) => household.id == activeHouseholdId)
      .firstOrNull;

  HouseholdState copyWith({
    HouseholdStatus? status,
    List<HouseholdSummary>? households,
    String? activeHouseholdId,
    bool clearActiveHousehold = false,
    String? errorMessage,
    bool clearError = false,
  }) => HouseholdState(
    status: status ?? this.status,
    households: households ?? this.households,
    activeHouseholdId: clearActiveHousehold
        ? null
        : activeHouseholdId ?? this.activeHouseholdId,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

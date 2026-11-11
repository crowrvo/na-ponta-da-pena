import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/finance_entries_repository.dart';
import '../domain/finance_entry.dart';
import 'finance_overview_state.dart';

class FinanceOverviewCubit extends Cubit<FinanceOverviewState> {
  FinanceOverviewCubit({
    required FinanceEntriesRepository repository,
    required String householdId,
    DateTime? now,
  }) : _repository = repository,
       _householdId = _requireHouseholdId(householdId),
       super(FinanceOverviewState.initial(now ?? DateTime.now()));

  final FinanceEntriesRepository _repository;
  final String _householdId;
  StreamSubscription<List<FinanceEntry>>? _entriesSubscription;
  StreamSubscription<MonthlyFinanceSummary>? _summarySubscription;
  StreamSubscription<int>? _pendingSubscription;

  Future<void> initialize() async {
    _pendingSubscription ??= _repository.watchPendingOperations().listen(
      (count) => emit(state.copyWith(pendingOperations: count)),
      onError: _handleStreamError,
    );
    await selectMonth(state.month);
  }

  Future<void> selectMonth(DateTime month) async {
    final normalized = DateTime.utc(month.year, month.month);
    emit(
      state.copyWith(
        month: normalized,
        status: FinanceOverviewStatus.loading,
        clearError: true,
      ),
    );
    await _entriesSubscription?.cancel();
    await _summarySubscription?.cancel();
    _entriesSubscription = _repository
        .watchEntriesForMonth(householdId: _householdId, month: normalized)
        .listen(
          (entries) => emit(
            state.copyWith(
              entries: entries,
              status: FinanceOverviewStatus.ready,
              clearError: true,
            ),
          ),
          onError: _handleStreamError,
        );
    _summarySubscription = _repository
        .watchSummaryForMonth(householdId: _householdId, month: normalized)
        .listen(
          (summary) => emit(state.copyWith(summary: summary)),
          onError: _handleStreamError,
        );
  }

  Future<bool> addEntry({
    required FinanceEntryDirection direction,
    required int amountInCents,
    required String description,
    required DateTime occurredAt,
  }) async {
    emit(
      state.copyWith(status: FinanceOverviewStatus.saving, clearError: true),
    );
    try {
      await _repository.addEntry(
        householdId: _householdId,
        direction: direction,
        amountInCents: amountInCents,
        description: description,
        occurredAt: occurredAt,
      );
      emit(state.copyWith(status: FinanceOverviewStatus.ready));
      return true;
    } catch (_) {
      emit(
        state.copyWith(
          status: FinanceOverviewStatus.failure,
          errorMessage: 'Não foi possível salvar o lançamento.',
        ),
      );
      return false;
    }
  }

  Future<void> showPreviousMonth() =>
      selectMonth(DateTime.utc(state.month.year, state.month.month - 1));

  Future<void> showNextMonth() =>
      selectMonth(DateTime.utc(state.month.year, state.month.month + 1));

  void _handleStreamError(Object _) {
    emit(
      state.copyWith(
        status: FinanceOverviewStatus.failure,
        errorMessage: 'Não foi possível carregar os dados locais.',
      ),
    );
  }

  @override
  Future<void> close() async {
    await _entriesSubscription?.cancel();
    await _summarySubscription?.cancel();
    await _pendingSubscription?.cancel();
    return super.close();
  }

  static String _requireHouseholdId(String value) {
    final normalized = value.trim();
    if (!_uuidPattern.hasMatch(normalized)) {
      throw ArgumentError.value(value, 'householdId', 'must be a UUID');
    }
    return normalized;
  }

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
}

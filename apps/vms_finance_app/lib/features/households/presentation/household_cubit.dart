import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/sync/connectivity_monitor.dart';
import '../data/household_api.dart';
import '../data/household_repository.dart';
import 'household_state.dart';

class HouseholdCubit extends Cubit<HouseholdState> {
  HouseholdCubit({
    required HouseholdStore repository,
    required ConnectivityMonitor connectivity,
  }) : _repository = repository,
       _connectivity = connectivity,
       super(const HouseholdState());

  final HouseholdStore _repository;
  final ConnectivityMonitor _connectivity;
  StreamSubscription<bool>? _connectivitySubscription;
  bool _online = false;

  Future<void> initialize() async {
    emit(state.copyWith(status: HouseholdStatus.loading, clearError: true));
    _connectivitySubscription ??= _connectivity.onConnectivityChanged.listen(
      (online) => unawaited(refresh(online: online)),
      onError: (_) => _failure('Não foi possível verificar a conexão.'),
    );
    await refresh(online: await _connectivity.isOnline);
  }

  Future<void> refresh({bool? online}) async {
    _online = online ?? _online;
    try {
      _apply(await _repository.refresh(online: _online));
    } on Object {
      _failure('Não foi possível carregar as famílias.');
    }
  }

  Future<bool> createHousehold(String name) => _mutate(
    () => _repository.createHousehold(name),
    fallbackMessage: 'Não foi possível criar a família.',
  );

  Future<bool> acceptInvitation(String invitationToken) => _mutate(
    () => _repository.acceptInvitation(invitationToken),
    fallbackMessage: 'Não foi possível aceitar o convite.',
  );

  Future<void> selectHousehold(String householdId) async {
    try {
      _apply(await _repository.selectHousehold(householdId));
    } on Object {
      _failure('Não foi possível selecionar a família.');
    }
  }

  Future<bool> _mutate(
    Future<HouseholdRefreshResult> Function() operation, {
    required String fallbackMessage,
  }) async {
    if (!_online) {
      _failure('Conecte-se à internet para concluir esta ação.');
      return false;
    }
    emit(state.copyWith(status: HouseholdStatus.saving, clearError: true));
    try {
      _apply(await operation());
      return true;
    } on HouseholdAuthenticationException {
      emit(
        state.copyWith(
          status: HouseholdStatus.authenticationRequired,
          errorMessage: 'Entre na sua conta para continuar.',
        ),
      );
    } on ArgumentError {
      _failure('Confira os dados informados.');
    } on HouseholdTransportException {
      _failure('Sem conexão com o servidor. Tente novamente.');
    } on Object {
      _failure(fallbackMessage);
    }
    return false;
  }

  void _apply(HouseholdRefreshResult result) {
    final status = switch (result.source) {
      HouseholdRefreshSource.authenticationRequired =>
        HouseholdStatus.authenticationRequired,
      HouseholdRefreshSource.offlineCache => HouseholdStatus.offline,
      HouseholdRefreshSource.remote =>
        result.households.isEmpty
            ? HouseholdStatus.empty
            : HouseholdStatus.ready,
    };
    emit(
      HouseholdState(
        status: status,
        households: result.households,
        activeHouseholdId: result.activeHouseholdId,
      ),
    );
  }

  void _failure(String message) {
    emit(
      state.copyWith(status: HouseholdStatus.failure, errorMessage: message),
    );
  }

  @override
  Future<void> close() async {
    await _connectivitySubscription?.cancel();
    return super.close();
  }
}

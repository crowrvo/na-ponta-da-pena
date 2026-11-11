import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vms_finance_app/core/sync/connectivity_monitor.dart';
import 'package:vms_finance_app/features/households/data/household_repository.dart';
import 'package:vms_finance_app/features/households/domain/household.dart';
import 'package:vms_finance_app/features/households/presentation/household_switcher.dart';

void main() {
  const household = HouseholdSummary(
    id: '11111111-1111-4111-8111-111111111111',
    name: 'Casa',
    role: HouseholdRole.owner,
  );

  Widget buildSubject({
    required HouseholdStore store,
    required ConnectivityMonitor connectivity,
    ValueChanged<HouseholdSummary>? onOpen,
  }) => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: HouseholdSwitcher(
          store: store,
          connectivityMonitor: connectivity,
          onOpenHousehold: onOpen ?? (_) {},
        ),
      ),
    ),
  );

  testWidgets('shows empty state and creates then opens a family', (
    tester,
  ) async {
    final store = WidgetHouseholdStore(
      refreshResult: const HouseholdRefreshResult(
        households: [],
        source: HouseholdRefreshSource.remote,
      ),
      mutationResult: const HouseholdRefreshResult(
        households: [household],
        source: HouseholdRefreshSource.remote,
        activeHouseholdId: '11111111-1111-4111-8111-111111111111',
      ),
    );
    final connectivity = WidgetConnectivity(true);
    HouseholdSummary? opened;
    await tester.pumpWidget(
      buildSubject(
        store: store,
        connectivity: connectivity,
        onOpen: (value) => opened = value,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Você ainda não participa de uma família financeira.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Criar família'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar'));
    await tester.pump();
    expect(find.text('Informe o nome da família.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome da família'),
      '  Casa  ',
    );
    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect(store.createdNames, ['  Casa  ']);
    expect(find.text('Abrir Casa'), findsOneWidget);
    await tester.tap(find.text('Abrir Casa'));
    expect(opened, household);
    await connectivity.close();
  });

  testWidgets('accepts an invitation without retaining the token in UI', (
    tester,
  ) async {
    final store = WidgetHouseholdStore(
      refreshResult: const HouseholdRefreshResult(
        households: [],
        source: HouseholdRefreshSource.remote,
      ),
      mutationResult: const HouseholdRefreshResult(
        households: [household],
        source: HouseholdRefreshSource.remote,
        activeHouseholdId: '11111111-1111-4111-8111-111111111111',
      ),
    );
    final connectivity = WidgetConnectivity(true);
    await tester.pumpWidget(
      buildSubject(store: store, connectivity: connectivity),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aceitar convite'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Token do convite'),
      'invitation-super-secret',
    );
    await tester.tap(find.text('Aceitar'));
    await tester.pumpAndSettle();

    expect(store.invitationTokens, ['invitation-super-secret']);
    expect(find.text('invitation-super-secret'), findsNothing);
    expect(find.text('Abrir Casa'), findsOneWidget);
    await connectivity.close();
  });

  testWidgets('shows cached family offline and disables mutations', (
    tester,
  ) async {
    final store = WidgetHouseholdStore(
      refreshResult: const HouseholdRefreshResult(
        households: [household],
        source: HouseholdRefreshSource.offlineCache,
        activeHouseholdId: '11111111-1111-4111-8111-111111111111',
      ),
    );
    final connectivity = WidgetConnectivity(false);
    await tester.pumpWidget(
      buildSubject(store: store, connectivity: connectivity),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Offline:'), findsOneWidget);
    expect(find.text('Casa'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Criar família'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Aceitar convite'),
          )
          .onPressed,
      isNull,
    );
    await connectivity.close();
  });

  testWidgets('shows authentication and failure states safely', (tester) async {
    final connectivity = WidgetConnectivity(true);
    final store = WidgetHouseholdStore(
      refreshResult: const HouseholdRefreshResult(
        households: [],
        source: HouseholdRefreshSource.authenticationRequired,
      ),
    );
    await tester.pumpWidget(
      buildSubject(store: store, connectivity: connectivity),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Entre na sua conta'), findsOneWidget);

    store.error = Exception('private server detail');
    connectivity.emit(true);
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível carregar as famílias.'), findsOneWidget);
    expect(find.textContaining('private server detail'), findsNothing);
    await connectivity.close();
  });
}

class WidgetConnectivity implements ConnectivityMonitor {
  WidgetConnectivity(this.online);

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

class WidgetHouseholdStore implements HouseholdStore {
  WidgetHouseholdStore({required this.refreshResult, this.mutationResult});

  HouseholdRefreshResult refreshResult;
  HouseholdRefreshResult? mutationResult;
  Object? error;
  final List<String> createdNames = [];
  final List<String> invitationTokens = [];

  void _throwIfNeeded() {
    if (error case final error?) throw error;
  }

  @override
  Future<HouseholdRefreshResult> refresh({required bool online}) async {
    _throwIfNeeded();
    return refreshResult;
  }

  @override
  Future<HouseholdRefreshResult> createHousehold(String name) async {
    createdNames.add(name);
    _throwIfNeeded();
    return mutationResult ?? refreshResult;
  }

  @override
  Future<HouseholdRefreshResult> acceptInvitation(
    String invitationToken,
  ) async {
    invitationTokens.add(invitationToken);
    _throwIfNeeded();
    return mutationResult ?? refreshResult;
  }

  @override
  Future<HouseholdRefreshResult> selectHousehold(String householdId) async {
    _throwIfNeeded();
    return mutationResult ?? refreshResult;
  }
}

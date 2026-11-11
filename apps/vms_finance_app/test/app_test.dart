import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vms_finance_app/core/auth/auth_session.dart';
import 'package:vms_finance_app/core/database/app_database.dart';
import 'package:vms_finance_app/core/sync/connectivity_monitor.dart';
import 'package:vms_finance_app/features/households/data/household_repository.dart';
import 'package:vms_finance_app/features/households/domain/household.dart';
import 'package:vms_finance_app/main.dart';

void main() {
  testWidgets('shows offline-first and safe sync configuration states', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(
      VmsFinanceApp(
        database: database,
        closeDatabaseOnDispose: false,
        authenticationSession: _AuthenticatedSession(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Finanças da família'), findsOneWidget);
    expect(find.text('Operações aguardando sincronização'), findsOneWidget);
    expect(
      find.text('A API ainda não foi configurada neste aplicativo.'),
      findsOneWidget,
    );
    expect(find.text('Criar lançamento local de teste'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final closeFuture = database.close();
    await tester.pump(const Duration(milliseconds: 1));
    await closeFuture;
  });

  testWidgets('opens the active household monthly overview', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(
      VmsFinanceApp(
        database: database,
        closeDatabaseOnDispose: false,
        connectivityMonitor: const _OnlineConnectivity(),
        householdStore: const _ReadyHouseholdStore(),
        authenticationSession: _AuthenticatedSession(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Abrir Casa'), findsOneWidget);
    await tester.tap(find.text('Abrir Casa'));
    await tester.pumpAndSettle();

    expect(find.text('Casa'), findsOneWidget);
    expect(
      find.text('Nenhum lançamento neste mês.\nUse o botão + para começar.'),
      findsOneWidget,
    );
    expect(find.text('Novo lançamento'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final closeFuture = database.close();
    await tester.pump(const Duration(milliseconds: 1));
    await closeFuture;
  });
}

class _AuthenticatedSession extends ChangeNotifier
    implements AuthenticationSession {
  @override
  String? errorMessage;

  @override
  AuthSessionStatus status = AuthSessionStatus.authenticated;

  @override
  String? userLabel = 'Test User';

  @override
  Future<void> initialize() async {}

  @override
  Future<void> login() async {}

  @override
  Future<void> logout() async {}

  @override
  Future<String?> readAccessToken() async => 'test-token';
}

class _OnlineConnectivity implements ConnectivityMonitor {
  const _OnlineConnectivity();

  @override
  Future<bool> get isOnline async => true;

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

class _ReadyHouseholdStore implements HouseholdStore {
  const _ReadyHouseholdStore();

  static const _household = HouseholdSummary(
    id: '11111111-1111-4111-8111-111111111111',
    name: 'Casa',
    role: HouseholdRole.owner,
  );

  static const _result = HouseholdRefreshResult(
    households: [_household],
    source: HouseholdRefreshSource.remote,
    activeHouseholdId: '11111111-1111-4111-8111-111111111111',
  );

  @override
  Future<HouseholdRefreshResult> refresh({required bool online}) async =>
      _result;

  @override
  Future<HouseholdRefreshResult> createHousehold(String name) async => _result;

  @override
  Future<HouseholdRefreshResult> acceptInvitation(
    String invitationToken,
  ) async => _result;

  @override
  Future<HouseholdRefreshResult> selectHousehold(String householdId) async =>
      _result;
}

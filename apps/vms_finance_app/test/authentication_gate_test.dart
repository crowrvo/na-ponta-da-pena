import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vms_finance_app/core/auth/auth_session.dart';
import 'package:vms_finance_app/core/auth/authentication_gate.dart';

void main() {
  testWidgets('login unlocks the authenticated app and logout clears it', (
    tester,
  ) async {
    final session = _FakeSession();
    await tester.pumpWidget(
      MaterialApp(
        home: AuthenticationGate(
          session: session,
          authenticatedBuilder: (_, logout) => Scaffold(
            body: Column(
              children: [
                const Text('authenticated'),
                TextButton(onPressed: logout, child: const Text('logout')),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Entrar com Auth0'), findsOneWidget);
    await tester.tap(find.text('Entrar com Auth0'));
    await tester.pump();
    expect(find.text('authenticated'), findsOneWidget);

    await tester.tap(find.text('logout'));
    await tester.pump();
    expect(find.text('Entrar com Auth0'), findsOneWidget);
  });
}

class _FakeSession extends ChangeNotifier implements AuthenticationSession {
  @override
  String? errorMessage;

  @override
  AuthSessionStatus status = AuthSessionStatus.unauthenticated;

  @override
  String? userLabel;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> login() async {
    status = AuthSessionStatus.authenticated;
    notifyListeners();
  }

  @override
  Future<void> logout() async {
    status = AuthSessionStatus.unauthenticated;
    notifyListeners();
  }

  @override
  Future<String?> readAccessToken() async => 'access-token';
}

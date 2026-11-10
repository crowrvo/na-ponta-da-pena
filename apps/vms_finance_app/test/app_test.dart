import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vms_finance_app/core/database/app_database.dart';
import 'package:vms_finance_app/main.dart';

void main() {
  testWidgets('shows offline-first and safe sync configuration states', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(
      VmsFinanceApp(database: database, closeDatabaseOnDispose: false),
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
}

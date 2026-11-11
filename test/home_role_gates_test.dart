import 'package:ferreteriabimetalica/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('employees retain shared queue and search without owner writes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(
          name: 'Emilia',
          email: 'employee@example.com',
          roleId: 2,
        ),
      ),
    );

    expect(find.text('Gestión de pedidos'), findsOneWidget);
    expect(find.text('Búsqueda de productos'), findsOneWidget);
    expect(find.text('Cuentas de usuario'), findsOneWidget);
    expect(find.text('Inventario'), findsNothing);
    expect(find.text('Registros de pago'), findsNothing);
    expect(find.text('Reportes y administración'), findsNothing);
  });

  testWidgets(
    'owner sees inventory, account management, reports and payments',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(name: 'Olga', email: 'owner@example.com', roleId: 1),
        ),
      );

      expect(find.text('Gestión de pedidos'), findsOneWidget);
      expect(find.text('Inventario'), findsOneWidget);
      expect(find.text('Cuentas de usuario'), findsOneWidget);
      expect(find.text('Registros de pago'), findsOneWidget);
      expect(find.text('Reportes y administración'), findsOneWidget);
    },
  );
}

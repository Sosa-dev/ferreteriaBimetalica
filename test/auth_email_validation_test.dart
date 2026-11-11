import 'package:ferreteriabimetalica/screens/auth_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login validates email format before submitting', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.enterText(find.byType(TextFormField).at(0), 'correo-invalido');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa un correo válido'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('registration validates email format before submitting', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana');
    await tester.enterText(find.byType(TextFormField).at(1), 'Pérez');
    await tester.enterText(find.byType(TextFormField).at(2), 'correo-invalido');
    await tester.enterText(find.byType(TextFormField).at(3), 'password');
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa un correo válido'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:ferreteriabimetalica/main.dart';

void main() {
  testWidgets('shows the login screen and registration action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FerreteriaApp());

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Registro de cliente'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
  });
}

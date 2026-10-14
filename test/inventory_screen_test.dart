import 'package:ferreteriabimetalica/screens/inventory_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('product form fits narrow screens with long dropdown options', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ProductFormScreen(
          categories: const [
            {
              'id_categoria': 1,
              'nombre': 'Herramientas de construcción y reparación',
            },
          ],
          locations: const [
            {
              'id_ubicacion': 1,
              'pasillo': 'Pasillo 01 - Herramientas',
              'estante': 'A1',
              'nivel': 'Nivel 2 (Vista)',
            },
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Ubicación'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final dropdowns = find.byType(DropdownButtonFormField<int>);
    final locationDropdown = dropdowns.last;
    await tester.pumpAndSettle();
    await tester.tap(locationDropdown);
    await tester.pumpAndSettle();

    expect(find.textContaining('Pasillo 01 - Herramientas'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ferreteriabimetalica/screens/invoice_screen.dart';

void main() {
  testWidgets('renders invoice amounts serialized as decimal strings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: InvoiceScreen(
          sale: {
            'id_venta': 27,
            'subtotal': '8.50',
            'iva': '1.11',
            'total_pagar': '9.61',
            'detalles': [
              {
                'nombre': 'Martillo',
                'cantidad': 1,
                'precio_unitario': '8.50',
                'subtotal': '8.50',
              },
            ],
          },
          invoice: null,
          invoiceError: 'Datos fiscales no configurados',
        ),
      ),
    );

    expect(find.text('\$8.50'), findsNWidgets(2));
    expect(find.text('\$1.11'), findsOneWidget);
    expect(find.text('\$9.61'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

import 'package:ferreteriabimetalica/models/product.dart';
import 'package:ferreteriabimetalica/screens/order_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('guest receipt lookup requires a 12-character access code', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GuestOrderLookupScreen()));
    await tester.enterText(find.byType(TextField).first, 'short-code');
    await tester.tap(find.text('Consultar pedido'));
    await tester.pumpAndSettle();

    expect(
      find.text('El código debe contener exactamente 12 caracteres.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('cart lines are organized and order action has concise label', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final product = Product(
      id: 1,
      code: 'FER-001',
      name: 'Taladro percutor de uso industrial',
      salePrice: 25.5,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: OrderCartScreen(
          items: {1: OrderCartLine(product: product, quantity: 2)},
          onCartChanged: () {},
          onOrderCreated: () {},
        ),
      ),
    );

    expect(find.text('Taladro percutor de uso industrial'), findsOneWidget);
    expect(find.text('Subtotal estimado: \$51.00'), findsOneWidget);
    expect(find.text('Confirmar pedido'), findsOneWidget);
    final exception = tester.takeException();
    expect(exception, isNull);
  });

  testWidgets('order receipt offers printing and shows API order total', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OrderReceiptScreen(
          order: {
            'id_pedido': 14,
            'total_pedido': '25.50',
            'nombre_cliente': 'Ana Pérez',
            'correo_cliente': 'ana@example.com',
            'telefono_cliente': '2222-2222',
            'estado': 'Pendiente',
          },
          details: [
            {
              'producto_codigo': 'FER-001',
              'producto_nombre': 'Taladro',
              'cantidad': 1,
              'precio_unitario': '25.50',
              'subtotal': '25.50',
            },
          ],
          guestMode: false,
        ),
      ),
    );

    expect(find.text('Imprimir comprobante'), findsOneWidget);
    expect(find.text('Monto del pedido (API)'), findsOneWidget);
    expect(find.text('\$25.50'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}

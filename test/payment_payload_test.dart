import 'package:ferreteriabimetalica/core/payment_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cash checkout omits payment reference', () {
    expect(buildPaymentPayload(method: 'Efectivo', reference: 'cash-ticket'), {
      'metodo_pago': 'Efectivo',
    });
  });

  test('non-cash reference is trimmed and optional', () {
    expect(
      buildPaymentPayload(method: 'Transferencia', reference: '  TR-25  '),
      {'metodo_pago': 'Transferencia', 'referencia_pago': 'TR-25'},
    );
    expect(buildPaymentPayload(method: 'Tarjeta'), {'metodo_pago': 'Tarjeta'});
  });
}

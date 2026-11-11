Map<String, dynamic> buildPaymentPayload({
  required String method,
  String? reference,
}) {
  final normalizedReference = reference?.trim();
  return {
    'metodo_pago': method,
    if (method != 'Efectivo' &&
        normalizedReference != null &&
        normalizedReference.isNotEmpty)
      'referencia_pago': normalizedReference,
  };
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ferreteriabimetalica/models/product.dart';

void main() {
  group('Product.fromJson', () {
    test('parses decimal prices serialized as strings by the API', () {
      final product = Product.fromJson({
        'id_producto': 1,
        'codigo': 'HM-001',
        'nombre': 'Martillo de uña curva 16 oz',
        'precio_venta': '8.50',
        'precio_compra': '5.50',
        'stock_actual': 25,
        'stock_minimo': 5,
      });

      expect(product.salePrice, 8.5);
      expect(product.purchasePrice, 5.5);
      expect(product.stock, 25);
    });

    test('parses numeric prices as well', () {
      final product = Product.fromJson({
        'id_producto': 2,
        'codigo': 'HM-002',
        'nombre': 'Destornillador',
        'precio_venta': 12.5,
        'precio_compra': 8,
      });

      expect(product.salePrice, 12.5);
      expect(product.purchasePrice, 8);
    });

    test('reports invalid decimal fields clearly', () {
      expect(
        () => Product.fromJson({
          'id_producto': 3,
          'precio_venta': 'no es un precio',
        }),
        throwsFormatException,
      );
    });
  });
}

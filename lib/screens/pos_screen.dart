import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/product.dart';
import 'invoice_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _search = TextEditingController();
  final _customerName = TextEditingController();
  final _document = TextEditingController();
  List<Product> _matches = [];
  final Map<int, _CartLine> _cart = {};
  String _customerType = 'Natural';
  bool _searching = false;
  bool _charging = false;
  String? _searchError;

  double get _subtotal =>
      _cart.values.fold(0, (sum, line) => sum + line.product.salePrice * line.qty);
  double get _tax => _subtotal * 0.13;
  double get _total => _subtotal + _tax;

  @override
  void dispose() {
    _search.dispose();
    _customerName.dispose();
    _document.dispose();
    super.dispose();
  }

  Future<void> _findProducts(String value) async {
    if (value.trim().isEmpty) {
      setState(() => _matches = []);
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final response = await ApiClient.instance.dio.get<List<dynamic>>(
        '/productos/buscar',
        queryParameters: {'nombre': value.trim(), 'limit': 20},
      );
      if (!mounted) return;
      setState(
        () => _matches = response.data!
            .map((item) => Product.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _searchError = ApiClient.instance.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _add(Product product) {
    setState(() {
      final existing = _cart[product.id];
      if (existing == null) {
        _cart[product.id] = _CartLine(product);
      } else if (product.stock == null || existing.qty < product.stock!) {
        existing.qty++;
      } else {
        _message('No hay más unidades disponibles de este producto', error: true);
      }
    });
  }

  void _setQuantity(int id, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cart.remove(id);
      } else {
        final line = _cart[id]!;
        final stock = line.product.stock;
        if (stock != null && quantity > stock) {
          _message('Existencia disponible: $stock', error: true);
        } else {
          line.qty = quantity;
        }
      }
    });
  }

  Future<void> _charge() async {
    if (_cart.isEmpty) {
      _message('Agrega al menos un producto al carrito', error: true);
      return;
    }
    if (_customerName.text.trim().isEmpty || _document.text.trim().isEmpty) {
      _message('Completa los datos de facturación', error: true);
      return;
    }
    setState(() => _charging = true);
    try {
      final saleResponse = await ApiClient.instance.dio.post(
        '/ventas',
        data: {
          'items': _cart.values
              .map((line) => {
                    'producto_id': line.product.id,
                    'cantidad': line.qty,
                  })
              .toList(),
          'datos_facturacion': {
            'tipo_cliente': _customerType,
            'nombre_razon_social': _customerName.text.trim(),
            'numero_documento': _document.text.trim(),
          },
        },
      );
      final sale = Map<String, dynamic>.from(saleResponse.data as Map);
      Map<String, dynamic>? invoice;
      String? invoiceError;
      try {
        final invoiceResponse = await ApiClient.instance.dio.get(
          '/ventas/${sale['id_venta']}/factura',
        );
        invoice = Map<String, dynamic>.from(invoiceResponse.data as Map);
      } catch (error) {
        invoiceError = ApiClient.instance.errorMessage(error);
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InvoiceScreen(
            sale: sale,
            invoice: invoice,
            invoiceError: invoiceError,
          ),
        ),
      );
      if (!mounted) return;
      setState(() {
        _cart.clear();
        _customerName.clear();
        _document.clear();
        _matches.clear();
        _search.clear();
      });
    } catch (error) {
      if (mounted) _message(ApiClient.instance.errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => _charging = false);
    }
  }

  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Punto de venta')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _search,
                onChanged: _findProducts,
                decoration: const InputDecoration(
                  labelText: 'Buscar producto',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              if (_searching) const LinearProgressIndicator(),
              if (_searchError != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(_searchError!),
                ),
              ..._matches.map(
                (product) => Card(
                  child: ListTile(
                    title: Text(product.name),
                    subtitle: Text(
                      '${product.code} · Existencia ${product.stock ?? 0} · '
                      '\$${product.salePrice.toStringAsFixed(2)}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Agregar',
                      onPressed: () => _add(product),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Carrito (${_cart.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (_cart.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Aún no agregas productos'),
                ),
              ..._cart.entries.map(
                (entry) => Card(
                  child: ListTile(
                    title: Text(entry.value.product.name),
                    subtitle: Text(
                      '\$${entry.value.product.salePrice.toStringAsFixed(2)} c/u',
                    ),
                    leading: IconButton(
                      onPressed: () => _setQuantity(entry.key, entry.value.qty - 1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${entry.value.qty}'),
                        IconButton(
                          onPressed: () =>
                              _setQuantity(entry.key, entry.value.qty + 1),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _amountLine('Subtotal', _subtotal),
                      _amountLine('IVA (13%)', _tax),
                      const Divider(),
                      _amountLine('Total', _total, bold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _customerType,
                decoration: const InputDecoration(labelText: 'Tipo de cliente'),
                items: const [
                  DropdownMenuItem(value: 'Natural', child: Text('Persona natural')),
                  DropdownMenuItem(value: 'Juridico', child: Text('Persona jurídica')),
                ],
                onChanged: (value) =>
                    setState(() => _customerType = value ?? 'Natural'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _customerName,
                decoration: const InputDecoration(
                  labelText: 'Nombre / razón social',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _document,
                decoration: const InputDecoration(
                  labelText: 'Número de documento',
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _charging ? null : _charge,
                icon: const Icon(Icons.point_of_sale),
                label: _charging
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Cobrar y generar factura'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _amountLine(String label, double amount, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
}

class _CartLine {
  _CartLine(this.product);

  final Product product;
  int qty = 1;
}

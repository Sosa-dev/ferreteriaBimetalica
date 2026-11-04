import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/product.dart';
import 'invoice_screen.dart';

class OrderCartLine {
  const OrderCartLine({required this.product, required this.quantity});

  final Product product;
  final int quantity;
}

class OrderCartScreen extends StatefulWidget {
  const OrderCartScreen({
    required this.items,
    required this.onCartChanged,
    required this.onOrderCreated,
    this.guestMode = false,
    super.key,
  });

  final Map<int, OrderCartLine> items;
  final VoidCallback onCartChanged;
  final VoidCallback onOrderCreated;
  final bool guestMode;

  @override
  State<OrderCartScreen> createState() => _OrderCartScreenState();
}

class _OrderCartScreenState extends State<OrderCartScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _document = TextEditingController();
  final _address = TextEditingController();
  String _customerType = 'Natural';
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _document.dispose();
    _address.dispose();
    super.dispose();
  }

  double get _total => widget.items.values.fold(
    0,
    (sum, line) => sum + line.product.salePrice * line.quantity,
  );

  void _changeQuantity(OrderCartLine line, int difference) {
    setState(() {
      final quantity = line.quantity + difference;
      if (quantity <= 0) {
        widget.items.remove(line.product.id);
      } else {
        widget.items[line.product.id] = OrderCartLine(
          product: line.product,
          quantity: quantity,
        );
      }
    });
    widget.onCartChanged();
  }

  Future<void> _createOrder() async {
    if (widget.items.isEmpty ||
        _submitting ||
        !_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final response = await ApiClient.instance.dio.post<Map<String, dynamic>>(
        widget.guestMode ? '/pedidos/invitado' : '/pedidos',
        data: {
          'items': widget.items.values
              .map(
                (line) => {
                  'producto_id': line.product.id,
                  'cantidad': line.quantity,
                },
              )
              .toList(),
          'datos_cliente': {
            'tipo_cliente': _customerType,
            'nombre_razon_social': _name.text.trim(),
            'correo': _email.text.trim(),
            'telefono': _phone.text.trim(),
            'numero_documento': _document.text.trim(),
            'direccion': _address.text.trim(),
          },
        },
      );
      final data = response.data!;
      final receipt = widget.guestMode
          ? Map<String, dynamic>.from(data['pedido'] as Map)
          : data;
      final receiptDetails = (data['detalles'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      widget.onOrderCreated();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => OrderReceiptScreen(
            order: receipt,
            details: receiptDetails,
            accessCode: data['codigo_acceso']?.toString(),
            guestMode: widget.guestMode,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _error = ApiClient.instance.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Carrito de compras')),
    body: widget.items.isEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.remove_shopping_cart_outlined, size: 56),
                const SizedBox(height: 12),
                const Text('Tu carrito está vacío'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Volver al catálogo'),
                ),
              ],
            ),
          )
        : Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      ...widget.items.values.map(
                        (line) => Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        line.product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '\$${line.product.salePrice.toStringAsFixed(2)} c/u',
                                      ),
                                      Text(
                                        'Subtotal: \$${(line.product.salePrice * line.quantity).toStringAsFixed(2)}',
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Quitar una unidad',
                                  onPressed: () => _changeQuantity(line, -1),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text('${line.quantity}'),
                                IconButton(
                                  tooltip: 'Agregar una unidad',
                                  onPressed: () => _changeQuantity(line, 1),
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Datos para el comprobante y factura',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: _customerType,
                                decoration: const InputDecoration(
                                  labelText: 'Tipo de cliente',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Natural',
                                    child: Text('Persona natural'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Juridico',
                                    child: Text('Persona jurídica'),
                                  ),
                                ],
                                onChanged: (value) => setState(
                                  () => _customerType = value ?? 'Natural',
                                ),
                              ),
                              const SizedBox(height: 10),
                              _checkoutField(
                                controller: _name,
                                label: 'Nombre completo / razón social',
                                validator: _required,
                              ),
                              const SizedBox(height: 10),
                              _checkoutField(
                                controller: _email,
                                label: 'Correo electrónico',
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  final required = _required(value);
                                  if (required != null) return required;
                                  return value!.contains('@')
                                      ? null
                                      : 'Ingresa un correo válido';
                                },
                              ),
                              const SizedBox(height: 10),
                              _checkoutField(
                                controller: _phone,
                                label: 'Teléfono',
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  final required = _required(value);
                                  if (required != null) return required;
                                  return value!.trim().length >= 7
                                      ? null
                                      : 'Ingresa un teléfono válido';
                                },
                              ),
                              const SizedBox(height: 10),
                              _checkoutField(
                                controller: _document,
                                label: 'Documento de identidad / fiscal',
                                validator: _required,
                              ),
                              const SizedBox(height: 10),
                              _checkoutField(
                                controller: _address,
                                label: 'Dirección',
                                validator: _required,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                widget.guestMode
                                    ? 'No necesitas crear una cuenta. Guarda el código del comprobante para consultar tu pedido.'
                                    : 'El pedido se paga en la ferretería. Al entregarlo, el empleado registrará el pago y se generará la factura.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Subtotal: \$${_total.toStringAsFixed(2)} · IVA estimado: \$${(_total * .13).toStringAsFixed(2)} · Total al retirar: \$${(_total * 1.13).toStringAsFixed(2)}',
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _submitting ? null : _createOrder,
                          icon: _submitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text(
                            _submitting
                                ? 'Enviando pedido...'
                                : 'Crear comprobante de pedido',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
  );

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'Este campo es obligatorio'
      : null;

  Widget _checkoutField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    decoration: InputDecoration(labelText: label),
    validator: validator,
  );
}

class OrderReceiptScreen extends StatelessWidget {
  const OrderReceiptScreen({
    required this.order,
    required this.details,
    required this.guestMode,
    this.accessCode,
    super.key,
  });

  final Map<String, dynamic> order;
  final List<Map<String, dynamic>> details;
  final String? accessCode;
  final bool guestMode;

  @override
  Widget build(BuildContext context) {
    final subtotal = _amount(order['total_pedido']);
    final tax = subtotal * .13;
    return Scaffold(
      appBar: AppBar(title: const Text('Comprobante de pedido')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    'Pedido #${order['id_pedido']}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Cliente: ${order['nombre_cliente']}'),
                  Text('Correo: ${order['correo_cliente']}'),
                  Text('Teléfono: ${order['telefono_cliente']}'),
                  const SizedBox(height: 12),
                  if (accessCode != null) ...[
                    const Text('Código privado de consulta'),
                    SelectableText(
                      accessCode!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF14283C),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  const Text(
                    'Presenta este comprobante en la ferretería para pagar y retirar. '
                    'Al cobrarlo, se registrará la venta y se generará la factura con estos datos.',
                  ),
                  if (guestMode)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Guarda el código y no lo compartas.'),
                    ),
                ],
              ),
            ),
          ),
          if (details.isNotEmpty)
            ...details.map(
              (detail) => Card(
                child: ListTile(
                  title: Text(
                    detail['producto_nombre']?.toString() ?? 'Producto',
                  ),
                  subtitle: Text(
                    '${detail['cantidad']} × \$${_amount(detail['precio_unitario']).toStringAsFixed(2)}',
                  ),
                  trailing: Text(
                    '\$${_amount(detail['subtotal']).toStringAsFixed(2)}',
                  ),
                ),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _receiptLine('Subtotal', subtotal),
                  _receiptLine('IVA estimado (13%)', tax),
                  const Divider(),
                  _receiptLine('Total al retirar', subtotal + tax, bold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('Volver a la tienda'),
          ),
        ],
      ),
    );
  }
}

class GuestOrderLookupScreen extends StatefulWidget {
  const GuestOrderLookupScreen({super.key});

  @override
  State<GuestOrderLookupScreen> createState() => _GuestOrderLookupScreenState();
}

class _GuestOrderLookupScreenState extends State<GuestOrderLookupScreen> {
  final _code = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _receipt;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    if (_code.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _receipt = null;
    });
    try {
      final response = await ApiClient.instance.dio.get(
        '/pedidos/consulta',
        options: Options(headers: {'X-Order-Access-Code': _code.text.trim()}),
      );
      if (!mounted) return;
      setState(
        () => _receipt = Map<String, dynamic>.from(response.data as Map),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _error = ApiClient.instance.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openGuestInvoice() async {
    try {
      final path = '/pedidos/consulta/factura';
      final response = await ApiClient.instance.dio.get(path);
      if (!mounted) return;
      final invoice = Map<String, dynamic>.from(response.data as Map);
      final sale = {
        'id_venta': invoice['id_factura'],
        'subtotal': invoice['subtotal'],
        'iva': invoice['iva'],
        'total_pagar': invoice['total_pagar'],
        'detalles': invoice['detalles'],
      };
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => InvoiceScreen(
            sale: sale,
            invoice: invoice,
            invoiceError: null,
            invoicePath: '/pedidos/consulta/factura',
            invoiceHeaders: {'X-Order-Access-Code': _code.text.trim()},
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.instance.errorMessage(error))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _receipt?['pedido'];
    final details = (_receipt?['detalles'] as List? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Consultar comprobante')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: _code,
            decoration: const InputDecoration(
              labelText: 'Código privado del comprobante',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loading ? null : _lookup,
            child: Text(_loading ? 'Consultando...' : 'Consultar pedido'),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
          if (order is Map) ...[
            const SizedBox(height: 18),
            Card(
              child: ListTile(
                title: Text('Pedido #${order['id_pedido']}'),
                subtitle: Text(
                  '${order['estado']} · Total estimado: '
                  '\$${_amount(_receipt?['total_estimado']).toStringAsFixed(2)}',
                ),
              ),
            ),
            ...details.map(
              (detail) => ListTile(
                title: Text(
                  detail['producto_nombre']?.toString() ?? 'Producto',
                ),
                subtitle: Text(
                  '${detail['cantidad']} × \$${_amount(detail['precio_unitario']).toStringAsFixed(2)}',
                ),
              ),
            ),
            const Text(
              'Presenta el comprobante en la ferretería para pagar y retirar tu pedido.',
            ),
            if (order['venta_id'] != null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _openGuestInvoice,
                icon: const Icon(Icons.receipt_long),
                label: const Text('Ver factura de la compra'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

Widget _receiptLine(String label, double amount, {bool bold = false}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
          ),
        ],
      ),
    );

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({this.successMessage, super.key});

  final String? successMessage;

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  final Map<int, List<Map<String, dynamic>>> _details = {};
  final Set<int> _loadingDetails = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    if (widget.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(widget.successMessage!)));
      });
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.instance.dio.get<List<dynamic>>(
        '/pedidos',
      );
      if (!mounted) return;
      setState(() {
        _orders = response.data!
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = ApiClient.instance.errorMessage(error);
        _loading = false;
      });
    }
  }

  Future<void> _loadDetails(int orderId) async {
    if (_details.containsKey(orderId) || !_loadingDetails.add(orderId)) return;
    setState(() {});
    try {
      final response = await ApiClient.instance.dio.get<List<dynamic>>(
        '/pedidos/$orderId/detalles',
      );
      if (!mounted) return;
      setState(() {
        _details[orderId] = response.data!
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.instance.errorMessage(error))),
      );
    } finally {
      _loadingDetails.remove(orderId);
      if (mounted) setState(() {});
    }
  }

  Future<void> _openCustomerInvoice(int saleId) async {
    try {
      final responses = await Future.wait([
        ApiClient.instance.dio.get('/ventas/$saleId'),
        ApiClient.instance.dio.get('/ventas/$saleId/factura'),
      ]);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => InvoiceScreen(
            sale: Map<String, dynamic>.from(responses[0].data as Map),
            invoice: Map<String, dynamic>.from(responses[1].data as Map),
            invoiceError: null,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.instance.errorMessage(error))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mis pedidos')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? _ErrorPanel(message: _error!, onRetry: _loadOrders)
        : RefreshIndicator(
            onRefresh: _loadOrders,
            child: _orders.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 160),
                      Center(child: Text('Aún no tienes pedidos')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      final orderId = (order['id_pedido'] as num).toInt();
                      final status = order['estado']?.toString() ?? '';
                      return Card(
                        child: ExpansionTile(
                          onExpansionChanged: (expanded) {
                            if (expanded) _loadDetails(orderId);
                          },
                          leading: const CircleAvatar(
                            child: Icon(Icons.receipt_long_outlined),
                          ),
                          title: Text('Pedido #$orderId'),
                          subtitle: Text(
                            '${_statusLabel(status)} · ${_dateLabel(order['fecha_hora'])}\n'
                            'Total: \$${_amount(order['total_pedido']).toStringAsFixed(2)}',
                          ),
                          children: [_orderDetails(orderId)],
                        ),
                      );
                    },
                  ),
          ),
  );

  Widget _orderDetails(int orderId) {
    if (_loadingDetails.contains(orderId)) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final details = _details[orderId];
    if (details == null) {
      return const ListTile(
        title: Text('No se pudieron cargar los productos.'),
      );
    }
    if (details.isEmpty) {
      return const ListTile(title: Text('Este pedido no tiene productos.'));
    }
    final order = _orders.firstWhere(
      (item) => (item['id_pedido'] as num).toInt() == orderId,
    );
    return Column(
      children: [
        ...details.map(
          (detail) => ListTile(
            dense: true,
            title: Text(
              detail['producto_nombre']?.toString() ??
                  'Producto #${detail['producto_id']}',
            ),
            subtitle: Text(
              '${detail['producto_codigo'] == null ? '' : '${detail['producto_codigo']} · '}'
              '${detail['cantidad']} × \$${_amount(detail['precio_unitario']).toStringAsFixed(2)}',
            ),
            trailing: Text(
              '\$${_amount(detail['subtotal']).toStringAsFixed(2)}',
            ),
          ),
        ),
        if (order['venta_id'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton.icon(
              onPressed: () =>
                  _openCustomerInvoice((order['venta_id'] as num).toInt()),
              icon: const Icon(Icons.receipt_long),
              label: const Text('Ver factura'),
            ),
          ),
      ],
    );
  }
}

class StaffOrdersScreen extends StatefulWidget {
  const StaffOrdersScreen({super.key});

  @override
  State<StaffOrdersScreen> createState() => _StaffOrdersScreenState();
}

class _StaffOrdersScreenState extends State<StaffOrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  final Map<int, List<Map<String, dynamic>>> _details = {};
  final Set<int> _loadingDetails = {};
  final Map<int, String> _detailErrors = {};
  bool _loading = true;
  final Set<int> _updating = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.instance.dio.get<List<dynamic>>(
        '/pedidos',
      );
      if (!mounted) return;
      setState(() {
        _orders = response.data!
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = ApiClient.instance.errorMessage(error);
        _loading = false;
      });
    }
  }

  Future<void> _loadOrderDetails(int orderId) async {
    if (_details.containsKey(orderId) || !_loadingDetails.add(orderId)) {
      return;
    }
    setState(() {
      _detailErrors.remove(orderId);
    });
    try {
      final response = await ApiClient.instance.dio.get<List<dynamic>>(
        '/pedidos/$orderId/detalles',
      );
      if (!mounted) return;
      setState(() {
        _details[orderId] = response.data!
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _detailErrors[orderId] = ApiClient.instance.errorMessage(error);
      });
    } finally {
      _loadingDetails.remove(orderId);
      if (mounted) setState(() {});
    }
  }

  Future<void> _advanceOrder(int orderId, String nextStatus) async {
    if (!_updating.add(orderId)) return;
    setState(() {});
    try {
      if (nextStatus == 'Entregado') {
        final method = await _choosePaymentMethod();
        if (method == null) return;
        final response = await ApiClient.instance.dio.post(
          '/pedidos/$orderId/entregar',
          data: {'metodo_pago': method},
        );
        final sale = Map<String, dynamic>.from(response.data as Map);
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
          MaterialPageRoute<void>(
            builder: (_) => InvoiceScreen(
              sale: sale,
              invoice: invoice,
              invoiceError: invoiceError,
            ),
          ),
        );
      } else {
        await ApiClient.instance.dio.put<Map<String, dynamic>>(
          '/pedidos/$orderId',
          data: {'estado': nextStatus},
        );
      }
      await _loadOrders();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.instance.errorMessage(error))),
        );
      }
    } finally {
      _updating.remove(orderId);
      if (mounted) setState(() {});
    }
  }

  Future<String?> _choosePaymentMethod() => showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Registrar pago del pedido'),
      children: [
        for (final method in const ['Efectivo', 'Tarjeta', 'Transferencia'])
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, method),
            child: Text(method),
          ),
      ],
    ),
  );

  Widget _orderDetailPanel(Map<String, dynamic> order, int orderId) {
    if (_loadingDetails.contains(orderId)) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final error = _detailErrors[orderId];
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(error, textAlign: TextAlign.center),
            TextButton(
              onPressed: () => _loadOrderDetails(orderId),
              child: const Text('Volver a cargar el detalle'),
            ),
          ],
        ),
      );
    }
    final details = _details[orderId];
    if (details == null) {
      return const SizedBox.shrink();
    }

    final subtotal = _amount(order['total_pedido']);
    final tax = subtotal * .13;
    final nextStatus = _nextStatus[order['estado']?.toString()];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          Text(
            'Datos del cliente',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _orderInfoRow(
            Icons.shopping_bag_outlined,
            order['usuario_id'] == null
                ? 'Compra como invitado'
                : 'Cliente registrado',
          ),
          _orderInfoRow(
            Icons.person_outline,
            '${order['nombre_cliente'] ?? 'Cliente'} · '
            '${order['tipo_cliente'] == 'Juridico' ? 'Persona jurídica' : 'Persona natural'}',
          ),
          _orderInfoRow(Icons.email_outlined, order['correo_cliente']),
          _orderInfoRow(Icons.phone_outlined, order['telefono_cliente']),
          _orderInfoRow(
            Icons.badge_outlined,
            'Documento: ${order['numero_documento'] ?? 'No indicado'}',
          ),
          _orderInfoRow(
            Icons.location_on_outlined,
            'Dirección: ${order['direccion_cliente'] ?? 'No indicada'}',
          ),
          const SizedBox(height: 16),
          Text(
            'Productos solicitados (${details.length})',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (details.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Este pedido no contiene productos.'),
            )
          else
            ...details.map(
              (detail) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  detail['producto_nombre']?.toString() ?? 'Producto',
                ),
                subtitle: Text(
                  'Código ${detail['producto_codigo'] ?? 'N/D'} · '
                  '${detail['cantidad']} × '
                  '\$${_amount(detail['precio_unitario']).toStringAsFixed(2)}',
                ),
                trailing: Text(
                  '\$${_amount(detail['subtotal']).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          const Divider(),
          _orderInfoRow(
            Icons.receipt_long_outlined,
            'Subtotal: \$${subtotal.toStringAsFixed(2)}',
          ),
          _orderInfoRow(
            Icons.percent,
            'IVA estimado (13%): \$${tax.toStringAsFixed(2)}',
          ),
          _orderInfoRow(
            Icons.payments_outlined,
            'Total estimado al cobrar: \$${(subtotal + tax).toStringAsFixed(2)}',
          ),
          if (nextStatus != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _updating.contains(orderId)
                  ? null
                  : () => _advanceOrder(orderId, nextStatus),
              icon: _updating.contains(orderId)
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      nextStatus == 'Entregado'
                          ? Icons.point_of_sale
                          : Icons.arrow_forward,
                    ),
              label: Text(
                _updating.contains(orderId)
                    ? 'Procesando...'
                    : nextStatus == 'Entregado'
                    ? 'Cobrar, entregar y generar factura'
                    : _nextActionLabel(nextStatus),
              ),
            ),
            if (nextStatus == 'Entregado')
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Se reutilizarán los productos y datos de este pedido; '
                  'no es necesario volver a cargarlos en el POS.',
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _orderInfoRow(IconData icon, Object? value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(value?.toString() ?? 'No indicado')),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Gestión de pedidos')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? _ErrorPanel(message: _error!, onRetry: _loadOrders)
        : RefreshIndicator(
            onRefresh: _loadOrders,
            child: _orders.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 160),
                      Center(child: Text('No hay pedidos registrados')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      final orderId = (order['id_pedido'] as num).toInt();
                      final status = order['estado']?.toString() ?? '';
                      final isWholesale = order['prioridad_mayorista'] == true;
                      return Card(
                        child: ExpansionTile(
                          onExpansionChanged: (expanded) {
                            if (expanded) _loadOrderDetails(orderId);
                          },
                          leading: const CircleAvatar(
                            child: Icon(Icons.shopping_bag_outlined),
                          ),
                          title: Text(
                            'Pedido #$orderId · ${_statusLabel(status)}',
                          ),
                          subtitle: Text(
                            '${order['nombre_cliente'] ?? 'Cliente'} · '
                            '${_dateLabel(order['fecha_hora'])}\n'
                            'Total antes de IVA: '
                            '\$${_amount(order['total_pedido']).toStringAsFixed(2)}',
                          ),
                          children: [
                            if (isWholesale)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Chip(
                                    avatar: const Icon(
                                      Icons.workspace_premium_outlined,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'Mayorista · compras 12 meses: '
                                      '\$${_amount(order['compras_12_meses']).toStringAsFixed(2)}',
                                    ),
                                  ),
                                ),
                              ),
                            _orderDetailPanel(order, orderId),
                          ],
                        ),
                      );
                    },
                  ),
          ),
  );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}

const _nextStatus = {
  'Pendiente': 'En preparacion',
  'En preparacion': 'Listo',
  'Listo': 'Entregado',
};

String _nextActionLabel(String status) => switch (status) {
  'En preparacion' => 'Iniciar preparación',
  'Listo' => 'Marcar como listo',
  'Entregado' => 'Marcar como entregado',
  _ => 'Actualizar estado',
};

String _statusLabel(String status) =>
    status == 'En preparacion' ? 'En preparación' : status;

double _amount(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _dateLabel(Object? value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  if (date == null) return 'Fecha no disponible';
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}

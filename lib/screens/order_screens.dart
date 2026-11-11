import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/api_client.dart';
import '../core/payment_payload.dart';
import '../models/product.dart';
import '../widgets/product_photo.dart';
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
            ivaEstimado: data['iva_estimado'],
            totalEstimado: data['total_estimado'],
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
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 64,
                                      height: 64,
                                      child: ProductPhoto(
                                        url: line.product.photoUrl,
                                        fit: BoxFit.contain,
                                        iconSize: 30,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            line.product.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '\$${line.product.salePrice.toStringAsFixed(2)} c/u',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Quitar producto',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        setState(
                                          () => widget.items.remove(
                                            line.product.id,
                                          ),
                                        );
                                        widget.onCartChanged();
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Subtotal: \$${(line.product.salePrice * line.quantity).toStringAsFixed(2)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 128,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            tooltip: 'Quitar una unidad',
                                            visualDensity:
                                                VisualDensity.compact,
                                            onPressed: () =>
                                                _changeQuantity(line, -1),
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                            ),
                                          ),
                                          Text(
                                            '${line.quantity}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Agregar una unidad',
                                            visualDensity:
                                                VisualDensity.compact,
                                            onPressed: () =>
                                                _changeQuantity(line, 1),
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
                                'Datos para tu pedido',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
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
                          'Subtotal estimado: \$${_total.toStringAsFixed(2)}',
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
                            _submitting ? 'Enviando...' : 'Confirmar pedido',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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
    this.ivaEstimado,
    this.totalEstimado,
    super.key,
  });

  final Map<String, dynamic> order;
  final List<Map<String, dynamic>> details;
  final String? accessCode;
  final bool guestMode;
  final Object? ivaEstimado;
  final Object? totalEstimado;

  @override
  Widget build(BuildContext context) {
    final subtotal = _amount(order['total_pedido']);
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
                  _receiptLine('Monto del pedido (API)', subtotal, bold: true),
                  if (totalEstimado != null) ...[
                    const Divider(),
                    _receiptLine('IVA estimado (API)', _amount(ivaEstimado)),
                    _receiptLine(
                      'Total estimado (API)',
                      _amount(totalEstimado),
                      bold: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _printOrderReceiptButton(
            context,
            order: order,
            details: details,
            accessCode: accessCode,
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
    final code = _code.text.trim();
    if (!RegExp(r'^[A-Za-z0-9_-]{12}$').hasMatch(code)) {
      setState(() {
        _receipt = null;
        _error = 'El código debe contener exactamente 12 caracteres.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _receipt = null;
    });
    try {
      final response = await ApiClient.instance.dio.get(
        '/pedidos/consulta',
        options: Options(headers: {'X-Order-Access-Code': code}),
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
      final response = await ApiClient.instance.dio.get(
        path,
        options: Options(headers: {'X-Order-Access-Code': _code.text.trim()}),
      );
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
            maxLength: 12,
            decoration: const InputDecoration(
              labelText: 'Código privado del comprobante',
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'El código tiene 12 caracteres. La API permite 10 consultas por IP cada 15 minutos.',
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
            const SizedBox(height: 8),
            _printOrderReceiptButton(
              context,
              order: Map<String, dynamic>.from(order),
              details: details,
              accessCode: _code.text.trim(),
              ivaEstimado: _receipt?['iva_estimado'],
              totalEstimado: _receipt?['total_estimado'],
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

Widget _printOrderReceiptButton(
  BuildContext context, {
  required Map<String, dynamic> order,
  required List<Map<String, dynamic>> details,
  String? accessCode,
  Object? ivaEstimado,
  Object? totalEstimado,
}) => OutlinedButton.icon(
  onPressed: () async {
    try {
      await _printOrderReceipt(
        order: order,
        details: details,
        accessCode: accessCode,
        ivaEstimado: ivaEstimado,
        totalEstimado: totalEstimado,
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo imprimir el comprobante: $error')),
        );
      }
    }
  },
  icon: const Icon(Icons.print_outlined),
  label: const Text('Imprimir comprobante'),
);

Future<void> _printOrderReceipt({
  required Map<String, dynamic> order,
  required List<Map<String, dynamic>> details,
  String? accessCode,
  Object? ivaEstimado,
  Object? totalEstimado,
}) async {
  final document = pw.Document();
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        pw.Text(
          'Comprobante de pedido',
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text('Pedido #${order['id_pedido'] ?? ''}'),
        pw.Text('Fecha: ${order['fecha_hora'] ?? 'No disponible'}'),
        pw.SizedBox(height: 12),
        pw.Text('Cliente: ${order['nombre_cliente'] ?? 'No indicado'}'),
        pw.Text('Correo: ${order['correo_cliente'] ?? 'No indicado'}'),
        pw.Text('Teléfono: ${order['telefono_cliente'] ?? 'No indicado'}'),
        pw.Text('Estado: ${order['estado'] ?? 'No disponible'}'),
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headers: const ['Código', 'Producto', 'Cant.', 'Precio', 'Subtotal'],
          data: details.map((detail) {
            return [
              detail['producto_codigo']?.toString() ?? '—',
              detail['producto_nombre']?.toString() ?? 'Producto',
              detail['cantidad']?.toString() ?? '0',
              '\$${_amount(detail['precio_unitario']).toStringAsFixed(2)}',
              '\$${_amount(detail['subtotal']).toStringAsFixed(2)}',
            ];
          }).toList(),
        ),
        pw.SizedBox(height: 16),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Monto del pedido (API): '
            '\$${_amount(order['total_pedido']).toStringAsFixed(2)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        if (totalEstimado != null) ...[
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'IVA estimado (API): '
              '\$${_amount(ivaEstimado).toStringAsFixed(2)}',
            ),
          ),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Total estimado (API): '
              '\$${_amount(totalEstimado).toStringAsFixed(2)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
        if (accessCode != null && accessCode.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          pw.Text(
            'Código privado de consulta: $accessCode',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Guárdalo y no lo compartas.'),
        ],
        pw.SizedBox(height: 20),
        pw.Text(
          'Este documento es un comprobante de pedido, no una factura ni un recibo de pago.',
        ),
      ],
    ),
  );
  await Printing.layoutPdf(onLayout: (_) async => document.save());
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
  final _clientFilter = TextEditingController();
  final Map<int, List<Map<String, dynamic>>> _details = {};
  final Set<int> _loadingDetails = {};
  final Map<int, String> _detailErrors = {};
  bool _loading = true;
  final Set<int> _updating = {};
  String? _error;
  String _statusFilter = '';
  DateTime? _startDate;
  DateTime? _endDate;

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
      final query = <String, dynamic>{};
      if (_statusFilter.isNotEmpty) query['estado'] = _statusFilter;
      if (_startDate != null) {
        query['fecha_inicio'] = _dateParam(_startDate!);
      }
      if (_endDate != null) query['fecha_fin'] = _dateParam(_endDate!);
      if (_clientFilter.text.trim().isNotEmpty) {
        query['cliente'] = _clientFilter.text.trim();
      }
      final response = await ApiClient.instance.dio.get<List<dynamic>>(
        '/pedidos',
        queryParameters: query,
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

  @override
  void dispose() {
    _clientFilter.dispose();
    super.dispose();
  }

  String _dateParam(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> _selectOrderDate({required bool start}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: (start ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateUtils.dateOnly(DateTime.now()),
    );
    if (selected == null || !mounted) return;
    final candidateStart = start ? selected : _startDate;
    final candidateEnd = start ? _endDate : selected;
    if (candidateStart != null &&
        candidateEnd != null &&
        candidateStart.isAfter(candidateEnd)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha inicial no puede ser posterior a la final.'),
        ),
      );
      return;
    }
    setState(() {
      if (start) {
        _startDate = DateUtils.dateOnly(selected);
      } else {
        _endDate = DateUtils.dateOnly(selected);
      }
    });
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
        final payment = await _choosePaymentMethod();
        if (payment == null) return;
        final response = await ApiClient.instance.dio.post(
          '/pedidos/$orderId/entregar',
          data: payment,
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

  Future<Map<String, dynamic>?> _choosePaymentMethod() async {
    var method = 'Efectivo';
    final reference = TextEditingController();
    try {
      return await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Registrar pago del pedido'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: method,
                  decoration: const InputDecoration(
                    labelText: 'Método de pago',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Efectivo',
                      child: Text('Efectivo'),
                    ),
                    DropdownMenuItem(value: 'Tarjeta', child: Text('Tarjeta')),
                    DropdownMenuItem(
                      value: 'Transferencia',
                      child: Text('Transferencia'),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => method = value ?? 'Efectivo'),
                ),
                if (method != 'Efectivo') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: reference,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Referencia de pago (opcional)',
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  final value = reference.text.trim();
                  if (value.length > 100) return;
                  Navigator.pop(
                    context,
                    buildPaymentPayload(method: method, reference: value),
                  );
                },
                child: const Text('Continuar'),
              ),
            ],
          ),
        ),
      );
    } finally {
      reference.dispose();
    }
  }

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
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _orders.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _orderFilters();
                if (_orders.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('No hay pedidos para estos filtros.'),
                    ),
                  );
                }
                final order = _orders[index - 1];
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
                    title: Text('Pedido #$orderId · ${_statusLabel(status)}'),
                    subtitle: Text(
                      '${order['nombre_cliente'] ?? 'Cliente'} · '
                      '${_dateLabel(order['fecha_hora'])}\n'
                      'Total antes de IVA: '
                      '\$${_amount(order['total_pedido']).toStringAsFixed(2)}',
                    ),
                    children: [
                      if (isWholesale)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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

  Widget _orderFilters() => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cola compartida de pedidos',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _statusFilter,
            decoration: const InputDecoration(labelText: 'Estado'),
            items: const [
              DropdownMenuItem(value: '', child: Text('Todos los estados')),
              DropdownMenuItem(value: 'Pendiente', child: Text('Pendiente')),
              DropdownMenuItem(
                value: 'En preparacion',
                child: Text('En preparación'),
              ),
              DropdownMenuItem(value: 'Listo', child: Text('Listo')),
              DropdownMenuItem(value: 'Entregado', child: Text('Entregado')),
            ],
            onChanged: (value) => setState(() => _statusFilter = value ?? ''),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _clientFilter,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _loadOrders(),
            decoration: const InputDecoration(
              labelText: 'Cliente, correo o documento',
              prefixIcon: Icon(Icons.person_search_outlined),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => _selectOrderDate(start: true),
                child: Text(
                  _startDate == null
                      ? 'Fecha inicial'
                      : 'Desde ${_dateParam(_startDate!)}',
                ),
              ),
              OutlinedButton(
                onPressed: () => _selectOrderDate(start: false),
                child: Text(
                  _endDate == null
                      ? 'Fecha final'
                      : 'Hasta ${_dateParam(_endDate!)}',
                ),
              ),
              FilledButton.icon(
                onPressed: _loadOrders,
                icon: const Icon(Icons.filter_alt_outlined),
                label: const Text('Filtrar'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _statusFilter = '';
                    _startDate = null;
                    _endDate = null;
                    _clientFilter.clear();
                  });
                  _loadOrders();
                },
                child: const Text('Limpiar'),
              ),
            ],
          ),
          if (_orders.isEmpty) ...[
            const SizedBox(height: 10),
            const Text('No hay pedidos para estos filtros.'),
          ],
        ],
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

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/api_client.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({
    required this.sale,
    required this.invoice,
    required this.invoiceError,
    super.key,
  });

  final Map<String, dynamic> sale;
  final Map<String, dynamic>? invoice;
  final String? invoiceError;

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  late Map<String, dynamic>? _invoice = widget.invoice;
  late String? _invoiceError = widget.invoiceError;
  bool _loadingInvoice = false;

  String _money(dynamic value) {
    final amount = switch (value) {
      num number => number.toDouble(),
      String text => double.tryParse(text),
      _ => null,
    };
    return amount == null ? '—' : '\$${amount.toStringAsFixed(2)}';
  }

  Future<void> _printInvoice() async {
    final document = pw.Document();
    final issuer = _invoice?['emisor'] as Map?;
    final details =
        (_invoice?['detalles'] as List?) ??
        (widget.sale['detalles'] as List? ?? []);
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(28),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                issuer?['nombre']?.toString() ?? 'Comprobante de venta',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (issuer != null) ...[
                pw.Text('Identificación: ${issuer['identificacion']}'),
                pw.Text('Dirección: ${issuer['direccion']}'),
                if (issuer['telefono'] != null)
                  pw.Text('Teléfono: ${issuer['telefono']}'),
              ],
              pw.SizedBox(height: 12),
              pw.Text(
                'Factura #${_invoice?['id_factura'] ?? widget.sale['id_venta']}',
              ),
              if (_invoice != null) ...[
                pw.Text('Cliente: ${_invoice!['nombre_razon_social']}'),
                pw.Text('Documento: ${_invoice!['numero_documento']}'),
              ],
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headers: const ['Producto', 'Cant.', 'Precio', 'Subtotal'],
                data: details.map((item) {
                  final row = item as Map;
                  return [
                    row['nombre']?.toString() ?? 'Producto',
                    row['cantidad']?.toString() ?? '0',
                    _money(row['precio_unitario']),
                    _money(row['subtotal']),
                  ];
                }).toList(),
              ),
              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Subtotal: ${_money(widget.sale['subtotal'])}'),
                    pw.Text('IVA: ${_money(widget.sale['iva'])}'),
                    pw.Text(
                      'Total: ${_money(widget.sale['total_pagar'])}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => document.save());
  }

  Future<void> _retryInvoice() async {
    setState(() {
      _loadingInvoice = true;
      _invoiceError = null;
    });
    try {
      final response = await ApiClient.instance.dio.get(
        '/ventas/${widget.sale['id_venta']}/factura',
      );
      if (!mounted) return;
      setState(() {
        _invoice = Map<String, dynamic>.from(response.data as Map);
        _invoiceError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _invoiceError = ApiClient.instance.errorMessage(error));
    } finally {
      if (mounted) setState(() => _loadingInvoice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final details =
        (_invoice?['detalles'] as List?) ??
        (widget.sale['detalles'] as List? ?? []);
    final issuer = _invoice?['emisor'] as Map?;
    return Scaffold(
      appBar: AppBar(title: const Text('Factura')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.receipt_long,
                    size: 38,
                    color: Color(0xFF455A64),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    issuer?['nombre']?.toString() ??
                        'Venta #${widget.sale['id_venta']} registrada',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (issuer != null) ...[
                    Text('Identificación: ${issuer['identificacion']}'),
                    Text('Dirección: ${issuer['direccion']}'),
                    if (issuer['telefono'] != null)
                      Text('Teléfono: ${issuer['telefono']}'),
                  ],
                  if (_invoice != null) ...[
                    const Divider(),
                    Text('Factura #${_invoice!['id_factura']}'),
                    Text('Cliente: ${_invoice!['nombre_razon_social']}'),
                    Text('Tipo: ${_invoice!['tipo_cliente']}'),
                    Text('Documento: ${_invoice!['numero_documento']}'),
                  ],
                ],
              ),
            ),
          ),
          if (_invoiceError != null)
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'La venta quedó registrada, pero la API no pudo generar los '
                  'datos fiscales de la factura. Revisa la configuración del emisor: '
                  '$_invoiceError',
                ),
              ),
            ),
          const SizedBox(height: 8),
          ...details.map((item) {
            final row = Map<String, dynamic>.from(item as Map);
            return Card(
              child: ListTile(
                title: Text(row['nombre']?.toString() ?? 'Producto'),
                subtitle: Text(
                  '${row['cantidad']} × ${_money(row['precio_unitario'])}',
                ),
                trailing: Text(_money(row['subtotal'])),
              ),
            );
          }),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _summaryLine('Subtotal', widget.sale['subtotal']),
                  _summaryLine('IVA', widget.sale['iva']),
                  const Divider(),
                  _summaryLine('Total', widget.sale['total_pagar'], bold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_invoice == null)
            OutlinedButton.icon(
              onPressed: _loadingInvoice ? null : _retryInvoice,
              icon: _loadingInvoice
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(
                _loadingInvoice
                    ? 'Consultando factura...'
                    : 'Reintentar factura',
              ),
            ),
          if (_invoice == null) const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _invoice == null ? null : _printInvoice,
            icon: const Icon(Icons.print_outlined),
            label: const Text('Imprimir factura'),
          ),
          if (_invoice == null)
            const Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                'La impresión se habilita cuando la API devuelve los datos '
                'fiscales configurados.',
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryLine(String label, dynamic value, {bool bold = false}) =>
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
              _money(value),
              style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
            ),
          ],
        ),
      );
}

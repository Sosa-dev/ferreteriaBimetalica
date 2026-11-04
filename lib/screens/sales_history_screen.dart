import 'package:flutter/material.dart';

import '../core/api_client.dart';
import 'invoice_screen.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  List<Map<String, dynamic>> _sales = [];
  bool _loading = true;
  String? _error;
  String _channel = 'Todas';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.instance.dio.get<List<dynamic>>(
        '/ventas',
        queryParameters: {
          if (_startDate != null) 'fecha_inicio': _dateParam(_startDate!),
          if (_endDate != null) 'fecha_fin': _dateParam(_endDate!),
          if (_channel != 'Todas') 'canal': _channel,
        },
      );
      if (!mounted) return;
      setState(() {
        _sales = response.data!
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

  Future<void> _openSale(int saleId) async {
    try {
      final saleResponse = await ApiClient.instance.dio.get('/ventas/$saleId');
      final sale = Map<String, dynamic>.from(saleResponse.data as Map);
      Map<String, dynamic>? invoice;
      String? invoiceError;
      try {
        final invoiceResponse = await ApiClient.instance.dio.get(
          '/ventas/$saleId/factura',
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
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.instance.errorMessage(error))),
      );
    }
  }

  String _dateLabel(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return 'Fecha no disponible';
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String _dateParam(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> _selectDate({required bool start}) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: (start ? _startDate : _endDate) ?? today,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (selected == null || !mounted) return;
    final startDate = start ? selected : _startDate;
    final endDate = start ? _endDate : selected;
    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha inicial no puede ser posterior a la final.'),
        ),
      );
      return;
    }
    setState(() {
      _startDate = startDate == null ? null : DateUtils.dateOnly(startDate);
      _endDate = endDate == null ? null : DateUtils.dateOnly(endDate);
    });
    await _loadSales();
  }

  double _amount(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;

  @override
  Widget build(BuildContext context) {
    final sales = _sales;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de ventas'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loadSales,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _loadSales,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _selectDate(start: true),
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          _startDate == null
                              ? 'Desde'
                              : 'Desde ${_dateParam(_startDate!)}',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _selectDate(start: false),
                        icon: const Icon(Icons.event_outlined),
                        label: Text(
                          _endDate == null
                              ? 'Hasta'
                              : 'Hasta ${_dateParam(_endDate!)}',
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          initialValue: _channel,
                          decoration: const InputDecoration(labelText: 'Canal'),
                          items: const [
                            DropdownMenuItem(
                              value: 'Todas',
                              child: Text('Todas'),
                            ),
                            DropdownMenuItem(
                              value: 'POS',
                              child: Text('Presencial'),
                            ),
                            DropdownMenuItem(
                              value: 'WEB',
                              child: Text('Pedido web'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _channel = value ?? 'Todas');
                            _loadSales();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: sales.isEmpty
                      ? const Center(child: Text('No hay ventas registradas'))
                      : RefreshIndicator(
                          onRefresh: _loadSales,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                            itemCount: sales.length,
                            itemBuilder: (context, index) {
                              final sale = sales[index];
                              final id = (sale['id_venta'] as num).toInt();
                              final channel = sale['canal'] == 'WEB'
                                  ? 'Pedido web'
                                  : 'Presencial';
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Icon(
                                      sale['canal'] == 'WEB'
                                          ? Icons.shopping_bag_outlined
                                          : Icons.point_of_sale,
                                    ),
                                  ),
                                  title: Text('Venta #$id · $channel'),
                                  subtitle: Text(
                                    '${_dateLabel(sale['fecha_hora'])}\n'
                                    'Atendió usuario #${sale['usuario_id']} · '
                                    'IVA \$${_amount(sale['iva']).toStringAsFixed(2)}',
                                  ),
                                  isThreeLine: true,
                                  trailing: Text(
                                    '\$${_amount(sale['total_pagar']).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onTap: () => _openSale(id),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

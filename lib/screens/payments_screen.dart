import 'package:flutter/material.dart';

import '../core/api_client.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<Map<String, dynamic>> _payments = [];
  DateTime? _startDate;
  DateTime? _endDate;
  String _method = '';
  bool _loading = true;
  String? _error;

  String _dateParam(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> _loadPayments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final params = <String, dynamic>{};
    if (_startDate != null) params['fecha_inicio'] = _dateParam(_startDate!);
    if (_endDate != null) params['fecha_fin'] = _dateParam(_endDate!);
    if (_method.isNotEmpty) params['metodo_pago'] = _method;
    try {
      final response = await ApiClient.instance.dio.get<List<dynamic>>(
        '/pagos',
        queryParameters: params,
      );
      if (!mounted) return;
      setState(() {
        _payments = response.data!
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = ApiClient.instance.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectDate({required bool start}) async {
    final current = start ? _startDate : _endDate;
    final selected = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateUtils.dateOnly(DateTime.now()),
    );
    if (selected == null || !mounted) return;
    final candidateStart = start ? selected : _startDate;
    final candidateEnd = start ? _endDate : selected;
    if (candidateStart != null &&
        candidateEnd != null &&
        candidateStart.isAfter(candidateEnd)) {
      _message('La fecha inicial no puede ser posterior a la fecha final.');
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

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Registros de pago'),
      actions: [
        IconButton(
          tooltip: 'Actualizar pagos',
          onPressed: _loadPayments,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton(
                      onPressed: () => _selectDate(start: true),
                      child: Text(
                        _startDate == null
                            ? 'Fecha inicial'
                            : 'Desde ${_dateParam(_startDate!)}',
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _selectDate(start: false),
                      child: Text(
                        _endDate == null
                            ? 'Fecha final'
                            : 'Hasta ${_dateParam(_endDate!)}',
                      ),
                    ),
                    SizedBox(
                      width: 190,
                      child: DropdownButtonFormField<String>(
                        initialValue: _method,
                        decoration: const InputDecoration(
                          labelText: 'Método de pago',
                        ),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Todos')),
                          DropdownMenuItem(
                            value: 'Efectivo',
                            child: Text('Efectivo'),
                          ),
                          DropdownMenuItem(
                            value: 'Tarjeta',
                            child: Text('Tarjeta'),
                          ),
                          DropdownMenuItem(
                            value: 'Transferencia',
                            child: Text('Transferencia'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _method = value ?? ''),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _loadPayments,
                        icon: const Icon(Icons.filter_alt_outlined),
                        label: const Text('Aplicar filtros'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Limpiar filtros',
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                          _method = '';
                        });
                        _loadPayments();
                      },
                      icon: const Icon(Icons.clear_all),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: _loadPayments,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          )
        else if (_payments.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('No hay pagos para los filtros seleccionados.'),
            ),
          )
        else
          ..._payments.map(_paymentCard),
      ],
    ),
  );

  Widget _paymentCard(Map<String, dynamic> payment) {
    final date = DateTime.tryParse(payment['fecha_hora']?.toString() ?? '');
    final formattedDate = date == null
        ? 'Fecha no disponible'
        : '${date.toLocal().day.toString().padLeft(2, '0')}/'
              '${date.toLocal().month.toString().padLeft(2, '0')}/'
              '${date.toLocal().year} '
              '${date.toLocal().hour.toString().padLeft(2, '0')}:'
              '${date.toLocal().minute.toString().padLeft(2, '0')}';
    final amount = payment['monto'] is num
        ? (payment['monto'] as num).toDouble()
        : double.tryParse(payment['monto']?.toString() ?? '') ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.payments_outlined)),
        title: Text(
          '${payment['metodo_pago'] ?? 'Pago'} · \$${amount.toStringAsFixed(2)}',
        ),
        subtitle: Text(
          'Venta #${payment['venta_id']} · ${payment['referencia'] == null ? 'Sin referencia' : 'Referencia ${payment['referencia']}'}\n'
          '${payment['usuario_id'] == null ? '' : 'Usuario #${payment['usuario_id']} · '}$formattedDate',
        ),
        isThreeLine: true,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/product.dart';

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
    super.key,
  });

  final Map<int, OrderCartLine> items;
  final VoidCallback onCartChanged;
  final VoidCallback onOrderCreated;

  @override
  State<OrderCartScreen> createState() => _OrderCartScreenState();
}

class _OrderCartScreenState extends State<OrderCartScreen> {
  bool _submitting = false;
  String? _error;

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
    if (widget.items.isEmpty || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final response = await ApiClient.instance.dio.post<Map<String, dynamic>>(
        '/pedidos',
        data: {
          'items': widget.items.values
              .map(
                (line) => {
                  'producto_id': line.product.id,
                  'cantidad': line.quantity,
                },
              )
              .toList(),
        },
      );
      final orderId = response.data?['id_pedido'];
      widget.onOrderCreated();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => CustomerOrdersScreen(
            successMessage: orderId == null
                ? 'Tu pedido se registró correctamente.'
                : 'Tu pedido #$orderId se registró correctamente.',
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
        : Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: widget.items.values
                      .map(
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
                      )
                      .toList(),
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
                        'Total estimado: \$${_total.toStringAsFixed(2)}',
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.titleLarge
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
                              : 'Confirmar pedido',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
  );
}

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
    return Column(
      children: details
          .map(
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
          )
          .toList(),
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

  Future<void> _advanceOrder(int orderId, String nextStatus) async {
    if (!_updating.add(orderId)) return;
    setState(() {});
    try {
      await ApiClient.instance.dio.put<Map<String, dynamic>>(
        '/pedidos/$orderId',
        data: {'estado': nextStatus},
      );
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
                      final nextStatus = _nextStatus[status];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(
                                  child: Icon(Icons.shopping_bag_outlined),
                                ),
                                title: Text('Pedido #$orderId'),
                                subtitle: Text(
                                  'Cliente #${order['usuario_id']} · ${_dateLabel(order['fecha_hora'])}\n'
                                  'Total: \$${_amount(order['total_pedido']).toStringAsFixed(2)}',
                                ),
                                isThreeLine: true,
                                trailing: Chip(
                                  label: Text(_statusLabel(status)),
                                ),
                              ),
                              if (nextStatus != null)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton.tonal(
                                    onPressed: _updating.contains(orderId)
                                        ? null
                                        : () => _advanceOrder(
                                            orderId,
                                            nextStatus,
                                          ),
                                    child: Text(
                                      _updating.contains(orderId)
                                          ? 'Actualizando...'
                                          : _nextActionLabel(nextStatus),
                                    ),
                                  ),
                                ),
                            ],
                          ),
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

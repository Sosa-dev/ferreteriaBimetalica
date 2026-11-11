import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/api_client.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _wholesaleThreshold = TextEditingController();
  bool _thresholdLoaded = false;
  bool _savingThreshold = false;
  late DateTime _startDate = DateUtils.dateOnly(
    DateTime.now().subtract(const Duration(days: 29)),
  );
  late DateTime _endDate = DateUtils.dateOnly(DateTime.now());
  late Future<_ReportData> _reportFuture = _loadReport();

  String _dateParam(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<_ReportData> _loadReport() async {
    final responses = await Future.wait([
      ApiClient.instance.dio.get(
        '/reportes/ventas',
        queryParameters: {
          'fecha_inicio': _dateParam(_startDate),
          'fecha_fin': _dateParam(_endDate),
        },
      ),
      ApiClient.instance.dio.get('/reportes/inventario'),
      ApiClient.instance.dio.get('/configuracion/mayoristas'),
    ]);
    final report = _ReportData.fromResponses(
      responses[0].data,
      responses[1].data,
      responses[2].data,
    );
    if (!_thresholdLoaded) {
      _wholesaleThreshold.text = report.wholesaleThreshold?.toString() ?? '';
      _thresholdLoaded = true;
    }
    return report;
  }

  @override
  void dispose() {
    _wholesaleThreshold.dispose();
    super.dispose();
  }

  void _refreshReport() {
    setState(() => _reportFuture = _loadReport());
  }

  Future<void> _saveWholesaleThreshold() async {
    final text = _wholesaleThreshold.text.trim();
    final amount = text.isEmpty ? null : double.tryParse(text);
    if (text.isNotEmpty && (amount == null || amount < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ingresa un monto válido o deja vacío para desactivar.',
          ),
        ),
      );
      return;
    }
    setState(() => _savingThreshold = true);
    try {
      await ApiClient.instance.dio.put(
        '/configuracion/mayoristas',
        data: {'umbral_mayorista': amount},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            amount == null
                ? 'La prioridad mayorista quedó desactivada.'
                : 'Umbral mayorista guardado.',
          ),
        ),
      );
      _refreshReport();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.instance.errorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _savingThreshold = false);
    }
  }

  Future<void> _selectDate({required bool start}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: start ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateUtils.dateOnly(DateTime.now()),
    );
    if (selected == null || !mounted) return;
    final newStart = start ? selected : _startDate;
    final newEnd = start ? _endDate : selected;
    if (newStart.isAfter(newEnd)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha inicial no puede ser posterior a la final.'),
        ),
      );
      return;
    }
    setState(() {
      _startDate = DateUtils.dateOnly(newStart);
      _endDate = DateUtils.dateOnly(newEnd);
      _reportFuture = _loadReport();
    });
  }

  Future<void> _exportPdf(_ReportData report) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'Ferretería Bimetálica',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Reporte administrativo | ${_dateParam(_startDate)} al '
            '${_dateParam(_endDate)}',
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Ventas: ${report.totalSales}    '
            'Ingresos: ${_money(report.revenue)}    '
            'IVA: ${_money(report.tax)}',
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Inventario: ${report.inventoryProducts} productos, '
            '${report.inventoryUnits} unidades, '
            '${report.inventoryLowStock} bajo mínimo, '
            '${report.inventoryOutOfStock} sin existencia',
          ),
          pw.Text(
            'Valor a costo: ${_money(report.inventoryCost)}    '
            'Valor de venta: ${_money(report.inventorySaleValue)}',
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Ventas por día',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const ['Fecha', 'Ventas', 'Ingresos'],
            data: report.dailySales
                .map(
                  (row) => [
                    row.date,
                    row.count.toString(),
                    _money(row.revenue),
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Productos más vendidos',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const ['Código', 'Producto', 'Unidades', 'Ingresos'],
            data: report.topProducts
                .map(
                  (product) => [
                    product.code,
                    product.name,
                    product.quantity.toString(),
                    _money(product.revenue),
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Productos por reponer',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Código',
              'Producto',
              'Categoría',
              'Stock',
              'Mínimo',
            ],
            data: report.restockItems
                .map(
                  (item) => [
                    item.code,
                    item.name,
                    item.category,
                    item.stock.toString(),
                    item.minimumStock.toString(),
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Productos de mayor valor de venta en inventario',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Código',
              'Producto',
              'Categoría',
              'Stock',
              'Valor',
            ],
            data: report.highValueItems
                .map(
                  (item) => [
                    item.code,
                    item.name,
                    item.category,
                    item.stock.toString(),
                    _money(item.saleValue),
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Inventario por categoría',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Categoría',
              'Productos',
              'Unidades',
              'Valor venta',
            ],
            data: report.inventoryByCategory
                .map(
                  (category) => [
                    category.name,
                    category.products.toString(),
                    category.units.toString(),
                    _money(category.saleValue),
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => document.save());
  }

  String _money(double amount) => '\$${amount.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes y administración'),
        actions: [
          IconButton(
            tooltip: 'Actualizar reportes',
            onPressed: _refreshReport,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _selectDate(start: true),
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text('Desde ${_dateParam(_startDate)}'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _selectDate(start: false),
                    icon: const Icon(Icons.event_outlined),
                    label: Text('Hasta ${_dateParam(_endDate)}'),
                  ),
                  FilledButton.icon(
                    onPressed: _refreshReport,
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('Consultar'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FutureBuilder<_ReportData>(
            future: _reportFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 36),
                        const SizedBox(height: 8),
                        Text(
                          ApiClient.instance.errorMessage(snapshot.error!),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _refreshReport,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final report = snapshot.requireData;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prioridad mayorista',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            report.wholesaleThreshold == null
                                ? 'Desactivada. Los pedidos no reciben prioridad hasta que configures el monto.'
                                : 'Activa para cuentas registradas con compras de '
                                      '\$${report.wholesaleThreshold!.toStringAsFixed(2)} '
                                      'o más en los últimos 12 meses.',
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SizedBox(
                                width: 240,
                                child: TextField(
                                  controller: _wholesaleThreshold,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Monto mínimo (USD)',
                                    hintText: 'Vacío desactiva la prioridad',
                                  ),
                                ),
                              ),
                              FilledButton(
                                onPressed: _savingThreshold
                                    ? null
                                    : _saveWholesaleThreshold,
                                child: Text(
                                  _savingThreshold ? 'Guardando...' : 'Guardar',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Solo se acumulan ventas asociadas a cuentas registradas. '
                            'Los pedidos de invitado no tienen historial de cliente verificado.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _MetricCard(
                        title: 'Ventas del período',
                        value: report.totalSales.toString(),
                        icon: Icons.point_of_sale,
                      ),
                      _MetricCard(
                        title: 'Ingresos',
                        value: _money(report.revenue),
                        icon: Icons.payments_outlined,
                      ),
                      _MetricCard(
                        title: 'IVA recaudado',
                        value: _money(report.tax),
                        icon: Icons.receipt_long_outlined,
                      ),
                      _MetricCard(
                        title: 'Valor inventario a costo',
                        value: _money(report.inventoryCost),
                        icon: Icons.inventory_2_outlined,
                      ),
                      _MetricCard(
                        title: 'Productos activos',
                        value: report.inventoryProducts.toString(),
                        icon: Icons.widgets_outlined,
                      ),
                      _MetricCard(
                        title: 'Unidades disponibles',
                        value: report.inventoryUnits.toString(),
                        icon: Icons.inventory_outlined,
                      ),
                      _MetricCard(
                        title: 'Bajo mínimo',
                        value: report.inventoryLowStock.toString(),
                        icon: Icons.warning_amber_outlined,
                      ),
                      _MetricCard(
                        title: 'Sin existencia',
                        value: report.inventoryOutOfStock.toString(),
                        icon: Icons.remove_shopping_cart_outlined,
                      ),
                      _MetricCard(
                        title: 'Valor inventario a venta',
                        value: _money(report.inventorySaleValue),
                        icon: Icons.sell_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _SectionCard(
                    title: 'Actividad diaria',
                    child: report.dailySales.isEmpty
                        ? const Text(
                            'No hay ventas en el período seleccionado.',
                          )
                        : _DailySalesChart(
                            data: report.dailySales,
                            money: _money,
                          ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Productos más vendidos',
                    child: report.topProducts.isEmpty
                        ? const Text(
                            'No hay productos vendidos en este período.',
                          )
                        : Column(
                            children: report.topProducts
                                .map(
                                  (product) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(product.name),
                                    subtitle: Text(
                                      '${product.code} · ${product.quantity} unidades',
                                    ),
                                    trailing: Text(_money(product.revenue)),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Inventario actual',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${report.inventoryProducts} productos · '
                          '${report.inventoryUnits} unidades disponibles',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Valor estimado a precio de venta: '
                          '${_money(report.inventorySaleValue)}',
                        ),
                        const Divider(height: 24),
                        if (report.inventoryByCategory.isEmpty)
                          const Text('No hay inventario activo.')
                        else
                          ...report.inventoryByCategory.map(
                            (category) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(category.name),
                              subtitle: Text(
                                '${category.products} productos · '
                                '${category.units} unidades',
                              ),
                              trailing: Text(_money(category.saleValue)),
                            ),
                          ),
                        const Divider(height: 24),
                        Text(
                          'Productos que requieren reposición (${report.restockItems.length})',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (report.restockItems.isEmpty)
                          const Text(
                            'No hay productos pendientes de reposición.',
                          )
                        else
                          ...report.restockItems.map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.name),
                              subtitle: Text(
                                '${item.code} · ${item.category} · '
                                'Stock ${item.stock} / mínimo ${item.minimumStock}',
                              ),
                              trailing: Text(_money(item.saleValue)),
                            ),
                          ),
                        const Divider(height: 24),
                        Text(
                          'Productos de mayor valor en inventario (${report.highValueItems.length})',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (report.highValueItems.isEmpty)
                          const Text('No hay productos activos.')
                        else
                          ...report.highValueItems.map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.name),
                              subtitle: Text(
                                '${item.code} · ${item.category} · Stock ${item.stock}',
                              ),
                              trailing: Text(_money(item.saleValue)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () => _exportPdf(report),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Exportar / imprimir PDF'),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEAF0F5),
                child: Icon(icon, color: const Color(0xFF14283C)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _DailySalesChart extends StatelessWidget {
  const _DailySalesChart({required this.data, required this.money});

  final List<_DailySale> data;
  final String Function(double) money;

  @override
  Widget build(BuildContext context) {
    final maxRevenue = data.fold<double>(
      0,
      (maximum, item) => item.revenue > maximum ? item.revenue : maximum,
    );
    return Column(
      children: data.map((item) {
        final progress = maxRevenue == 0 ? 0.0 : item.revenue / maxRevenue;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              SizedBox(width: 90, child: Text(item.date)),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: const Color(0xFFEAF0F5),
                    color: const Color(0xFFF47721),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 106,
                child: Text(money(item.revenue), textAlign: TextAlign.end),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ReportData {
  const _ReportData({
    required this.totalSales,
    required this.revenue,
    required this.tax,
    required this.dailySales,
    required this.topProducts,
    required this.inventoryProducts,
    required this.inventoryUnits,
    required this.inventoryCost,
    required this.inventorySaleValue,
    required this.inventoryLowStock,
    required this.inventoryOutOfStock,
    required this.restockItems,
    required this.highValueItems,
    required this.inventoryByCategory,
    required this.wholesaleThreshold,
  });

  final int totalSales;
  final double revenue;
  final double tax;
  final List<_DailySale> dailySales;
  final List<_TopProduct> topProducts;
  final int inventoryProducts;
  final int inventoryUnits;
  final double inventoryCost;
  final double inventorySaleValue;
  final int inventoryLowStock;
  final int inventoryOutOfStock;
  final List<_InventoryItem> restockItems;
  final List<_InventoryItem> highValueItems;
  final List<_InventoryCategory> inventoryByCategory;
  final double? wholesaleThreshold;

  factory _ReportData.fromResponses(
    dynamic salesData,
    dynamic inventoryData,
    dynamic settingsData,
  ) {
    final sales = Map<String, dynamic>.from(salesData as Map);
    final inventory = Map<String, dynamic>.from(inventoryData as Map);
    final settings = Map<String, dynamic>.from(settingsData as Map);
    return _ReportData(
      totalSales: _asInt(sales['total_ventas']),
      revenue: _asDouble(sales['ingresos']),
      tax: _asDouble(sales['iva']),
      dailySales: (sales['ventas_por_dia'] as List? ?? [])
          .map((item) => _DailySale.fromMap(item as Map))
          .toList(),
      topProducts: (sales['productos_mas_vendidos'] as List? ?? [])
          .map((item) => _TopProduct.fromMap(item as Map))
          .toList(),
      inventoryProducts: _asInt(inventory['total_productos']),
      inventoryUnits: _asInt(inventory['unidades_disponibles']),
      inventoryCost: _asDouble(inventory['valor_inventario_compra']),
      inventorySaleValue: _asDouble(inventory['valor_inventario_venta']),
      inventoryLowStock: _asInt(inventory['productos_bajo_stock']),
      inventoryOutOfStock: _asInt(inventory['productos_sin_stock']),
      restockItems: (inventory['productos_reponer'] as List? ?? [])
          .map((item) => _InventoryItem.fromMap(item as Map))
          .toList(),
      highValueItems: (inventory['productos_mayor_valor'] as List? ?? [])
          .map((item) => _InventoryItem.fromMap(item as Map))
          .toList(),
      inventoryByCategory: (inventory['por_categoria'] as List? ?? [])
          .map((item) => _InventoryCategory.fromMap(item as Map))
          .toList(),
      wholesaleThreshold: settings['umbral_mayorista'] == null
          ? null
          : _asDouble(settings['umbral_mayorista']),
    );
  }

  static int _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

  static double _asDouble(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
}

class _DailySale {
  const _DailySale(this.date, this.count, this.revenue);

  final String date;
  final int count;
  final double revenue;

  factory _DailySale.fromMap(Map row) => _DailySale(
    row['fecha']?.toString() ?? '',
    _ReportData._asInt(row['cantidad_ventas']),
    _ReportData._asDouble(row['ingresos']),
  );
}

class _TopProduct {
  const _TopProduct(this.code, this.name, this.quantity, this.revenue);

  final String code;
  final String name;
  final int quantity;
  final double revenue;

  factory _TopProduct.fromMap(Map row) => _TopProduct(
    row['codigo']?.toString() ?? '',
    row['nombre']?.toString() ?? '',
    _ReportData._asInt(row['cantidad_vendida']),
    _ReportData._asDouble(row['ingresos']),
  );
}

class _InventoryCategory {
  const _InventoryCategory(
    this.name,
    this.products,
    this.units,
    this.saleValue,
  );

  final String name;
  final int products;
  final int units;
  final double saleValue;

  factory _InventoryCategory.fromMap(Map row) => _InventoryCategory(
    row['categoria']?.toString() ?? '',
    _ReportData._asInt(row['productos']),
    _ReportData._asInt(row['unidades']),
    _ReportData._asDouble(row['valor_venta']),
  );
}

class _InventoryItem {
  const _InventoryItem({
    required this.code,
    required this.name,
    required this.category,
    required this.stock,
    required this.minimumStock,
    required this.purchaseValue,
    required this.saleValue,
  });

  final String code;
  final String name;
  final String category;
  final int stock;
  final int minimumStock;
  final double purchaseValue;
  final double saleValue;

  factory _InventoryItem.fromMap(Map row) => _InventoryItem(
    code: row['codigo']?.toString() ?? '',
    name: row['nombre']?.toString() ?? '',
    category: row['categoria']?.toString() ?? '',
    stock: _ReportData._asInt(row['stock_actual']),
    minimumStock: _ReportData._asInt(row['stock_minimo']),
    purchaseValue: _ReportData._asDouble(row['valor_compra']),
    saleValue: _ReportData._asDouble(row['valor_venta']),
  );
}

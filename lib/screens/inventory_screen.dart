import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/product.dart';
import '../widgets/product_photo.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _api = ApiClient.instance;
  List<Product> _products = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _locations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final responses = await Future.wait([
        _api.dio.get<List<dynamic>>('/productos'),
        _api.dio.get<List<dynamic>>('/categorias'),
        _api.dio.get<List<dynamic>>('/ubicaciones'),
      ]);
      if (!mounted) return;
      setState(() {
        _products = responses[0].data!
            .map(
              (item) =>
                  Product.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
        _categories = _maps(responses[1].data!);
        _locations = _maps(responses[2].data!);
      });
    } catch (error) {
      if (mounted) setState(() => _error = _api.errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _maps(List<dynamic> data) =>
      data.map((item) => Map<String, dynamic>.from(item as Map)).toList();

  Future<void> _editProduct([Product? product]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(
          categories: _categories,
          locations: _locations,
          product: product,
        ),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _editCatalogEntry({
    required String title,
    required String path,
    Map<String, dynamic>? entry,
    bool location = false,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          _CatalogEntryDialog(title: title, entry: entry, location: location),
    );
    if (result == null) return;
    try {
      final id = result['id'] as int?;
      if (id == null) {
        await _api.dio.post(path, data: result['payload']);
      } else {
        await _api.dio.put('$path/$id', data: result['payload']);
      }
      await _load();
    } catch (error) {
      if (mounted) _message(_api.errorMessage(error), error: true);
    }
  }

  Future<void> _deleteEntry(String path, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar elemento'),
        content: const Text('¿Confirmas que deseas eliminarlo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.dio.delete('$path/$id');
      await _load();
    } catch (error) {
      if (mounted) _message(_api.errorMessage(error), error: true);
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
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(text: 'Productos', icon: Icon(Icons.inventory_2_outlined)),
            Tab(text: 'Categorías', icon: Icon(Icons.category_outlined)),
            Tab(text: 'Ubicaciones', icon: Icon(Icons.place_outlined)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _load)
          : TabBarView(
              children: [
                _productList(),
                _entryList(
                  title: 'Categorías',
                  entries: _categories,
                  idKey: 'id_categoria',
                  label: (e) => e['nombre']?.toString() ?? '',
                  path: '/categorias',
                ),
                _entryList(
                  title: 'Ubicaciones',
                  entries: _locations,
                  idKey: 'id_ubicacion',
                  label: (e) =>
                      'Pasillo ${e['pasillo']} · Estante ${e['estante']} · Nivel ${e['nivel']}',
                  path: '/ubicaciones',
                  location: true,
                ),
              ],
            ),
    ),
  );

  Widget _productList() => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: () => _editProduct(),
          icon: const Icon(Icons.add),
          label: const Text('Agregar producto'),
        ),
        const SizedBox(height: 12),
        if (_products.isEmpty)
          const _EmptyState(label: 'No hay productos registrados'),
        ..._products.map(
          (product) => Card(
            child: ListTile(
              leading: SizedBox.square(
                dimension: 56,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ProductPhoto(
                    url: product.photoUrl,
                    fit: BoxFit.cover,
                    iconSize: 28,
                  ),
                ),
              ),
              title: Text(product.name),
              subtitle: Text(
                '${product.code} · \$${product.salePrice.toStringAsFixed(2)}'
                '${product.stock == null ? '' : ' · Stock: ${product.stock}'}',
              ),
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: 'Editar producto',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editProduct(product),
                  ),
                  IconButton(
                    tooltip: 'Eliminar producto',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteEntry('/productos', product.id),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _entryList({
    required String title,
    required List<Map<String, dynamic>> entries,
    required String idKey,
    required String Function(Map<String, dynamic>) label,
    required String path,
    bool location = false,
  }) => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: () =>
              _editCatalogEntry(title: title, path: path, location: location),
          icon: const Icon(Icons.add),
          label: Text('Agregar $title'.toLowerCase()),
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          _EmptyState(label: 'No hay ${title.toLowerCase()} registradas'),
        ...entries.map((entry) {
          final id = (entry[idKey] as num).toInt();
          return Card(
            child: ListTile(
              title: Text(label(entry)),
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editCatalogEntry(
                      title: title,
                      path: path,
                      entry: entry,
                      location: location,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Eliminar',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteEntry(path, id),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    ),
  );
}

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({
    required this.categories,
    required this.locations,
    this.product,
    super.key,
  });

  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> locations;
  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  int? _categoryId;
  int? _locationId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _fields = {
      'codigo': TextEditingController(text: p?.code ?? ''),
      'nombre': TextEditingController(text: p?.name ?? ''),
      'marca': TextEditingController(text: p?.brand ?? ''),
      'medida_presentacion': TextEditingController(text: p?.measure ?? ''),
      'precio_compra': TextEditingController(),
      'descripcion': TextEditingController(text: p?.description ?? ''),
      'precio_venta': TextEditingController(
        text: p?.salePrice.toString() ?? '',
      ),
      'stock_actual': TextEditingController(text: p?.stock?.toString() ?? '0'),
      'stock_minimo': TextEditingController(
        text: p?.minimumStock?.toString() ?? '0',
      ),
      'fotografia_url': TextEditingController(text: p?.photoUrl ?? ''),
    };
    _fields['precio_compra']!.text = p?.purchasePrice?.toString() ?? '';
    _categoryId =
        p?.categoryId ??
        (widget.categories.isEmpty
            ? null
            : (widget.categories.first['id_categoria'] as num).toInt());
    _locationId =
        p?.locationId ??
        (widget.locations.isEmpty
            ? null
            : (widget.locations.first['id_ubicacion'] as num).toInt());
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null || _locationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registra una categoría y ubicación primero'),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    final payload = <String, dynamic>{
      for (final entry in _fields.entries)
        entry.key: entry.value.text.trim().isEmpty
            ? null
            : entry.value.text.trim(),
      'precio_compra': double.tryParse(_fields['precio_compra']!.text) ?? 0,
      'precio_venta': double.parse(_fields['precio_venta']!.text),
      'stock_actual': int.parse(_fields['stock_actual']!.text),
      'stock_minimo': int.parse(_fields['stock_minimo']!.text),
      'categoria_id': _categoryId,
      'ubicacion_id': _locationId,
      'estado': true,
    };
    try {
      final product = widget.product;
      if (product == null) {
        await ApiClient.instance.dio.post('/productos', data: payload);
      } else {
        await ApiClient.instance.dio.put(
          '/productos/${product.id}',
          data: payload,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.instance.errorMessage(error)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.product == null ? 'Nuevo producto' : 'Editar producto',
      ),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _textField('codigo', 'Código', required: true),
          _textField('nombre', 'Nombre', required: true),
          _textField('marca', 'Marca'),
          _textField('medida_presentacion', 'Medida / presentación'),
          _textField('precio_compra', 'Precio de compra', number: true),
          _textField(
            'precio_venta',
            'Precio de venta',
            number: true,
            required: true,
          ),
          _textField(
            'stock_actual',
            'Existencia actual',
            number: true,
            integer: true,
          ),
          _textField(
            'stock_minimo',
            'Existencia mínima',
            number: true,
            integer: true,
          ),
          _textField('fotografia_url', 'URL de fotografía'),
          _textField('descripcion', 'Descripción', lines: 3),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _categoryId,
            decoration: const InputDecoration(labelText: 'Categoría'),
            items: widget.categories
                .map(
                  (category) => DropdownMenuItem(
                    value: (category['id_categoria'] as num).toInt(),
                    child: Text(category['nombre'].toString()),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _categoryId = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _locationId,
            decoration: const InputDecoration(labelText: 'Ubicación'),
            items: widget.locations
                .map(
                  (location) => DropdownMenuItem(
                    value: (location['id_ubicacion'] as num).toInt(),
                    child: Text(
                      '${location['pasillo']} · ${location['estante']} · ${location['nivel']}',
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _locationId = value),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const CircularProgressIndicator()
                : const Text('Guardar producto'),
          ),
        ],
      ),
    ),
  );

  Widget _textField(
    String key,
    String label, {
    bool required = false,
    bool number = false,
    bool integer = false,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: _fields[key],
      maxLines: lines,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'Campo obligatorio';
        }
        if (number && value != null && value.isNotEmpty) {
          final parsed = integer ? int.tryParse(value) : double.tryParse(value);
          if (parsed == null) return 'Ingresa un número válido';
        }
        return null;
      },
    ),
  );
}

class _CatalogEntryDialog extends StatefulWidget {
  const _CatalogEntryDialog({
    required this.title,
    this.entry,
    this.location = false,
  });

  final String title;
  final Map<String, dynamic>? entry;
  final bool location;

  @override
  State<_CatalogEntryDialog> createState() => _CatalogEntryDialogState();
}

class _CatalogEntryDialogState extends State<_CatalogEntryDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _shelfController;
  late final TextEditingController _levelController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.entry?[widget.location ? 'pasillo' : 'nombre']?.toString(),
    );
    _shelfController = TextEditingController(
      text: widget.entry?['estante']?.toString(),
    );
    _levelController = TextEditingController(
      text: widget.entry?['nivel']?.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shelfController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      '${widget.entry == null ? 'Nueva' : 'Editar'} ${widget.title.toLowerCase()}',
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: widget.location ? 'Pasillo' : 'Nombre',
          ),
        ),
        if (widget.location) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _shelfController,
            decoration: const InputDecoration(labelText: 'Estante'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _levelController,
            decoration: const InputDecoration(labelText: 'Nivel'),
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
          final first = _nameController.text.trim();
          final shelf = _shelfController.text.trim();
          final level = _levelController.text.trim();
          if (first.isNotEmpty &&
              (!widget.location || (shelf.isNotEmpty && level.isNotEmpty))) {
            Navigator.pop(context, {
              'id':
                  (widget.entry?[widget.location
                              ? 'id_ubicacion'
                              : 'id_categoria']
                          as num?)
                      ?.toInt(),
              'payload': widget.location
                  ? {'pasillo': first, 'estante': shelf, 'nivel': level}
                  : {'nombre': first},
            });
          }
        },
        child: const Text('Guardar'),
      ),
    ],
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(child: Text(label)),
  );
}

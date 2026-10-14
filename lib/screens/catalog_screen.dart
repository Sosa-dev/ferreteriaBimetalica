import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/product.dart';
import '../widgets/product_photo.dart';
import 'order_screens.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({required this.employeeMode, super.key});

  final bool employeeMode;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _searchField = 'nombre';
  List<Product> _products = [];
  final Map<int, OrderCartLine> _cart = {};
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _search);
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final query = _searchController.text.trim();
      final response = await ApiClient.instance.dio.get<List<dynamic>>(
        widget.employeeMode ? '/productos/buscar' : '/catalogo/productos',
        queryParameters: {
          if (query.isNotEmpty) _searchField: query,
          'limit': 50,
        },
      );
      if (!mounted) return;
      setState(
        () => _products = response.data!
            .map(
              (item) =>
                  Product.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList(),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _error = ApiClient.instance.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: widget.employeeMode
          ? const Text('Búsqueda de productos')
          : Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Image.asset('assets/branding/bimetalica_icon.png'),
                ),
                const SizedBox(width: 10),
                const Text('Bimetálica'),
              ],
            ),
      actions: [
        if (!widget.employeeMode)
          IconButton(
            tooltip: 'Carrito',
            onPressed: _openCart,
            icon: Badge(
              label: Text(
                '${_cart.values.fold<int>(0, (sum, line) => sum + line.quantity)}',
              ),
              isLabelVisible: _cart.isNotEmpty,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
      ],
    ),
    body: Column(
      children: [
        if (!widget.employeeMode)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Color(0xFFF47721)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Todo para tu próximo proyecto',
                        style: TextStyle(
                          color: Color(0xFF14283C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Explora productos y consulta sus precios.',
                        style: TextStyle(color: Color(0xFF536273)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, widget.employeeMode ? 16 : 8, 16, 8),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Buscar producto',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _search();
                    },
                    icon: const Icon(Icons.clear),
                  ),
                ),
              ),
              if (widget.employeeMode) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _searchField,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por',
                    prefixIcon: Icon(Icons.tune),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'nombre', child: Text('Nombre')),
                    DropdownMenuItem(value: 'codigo', child: Text('Código')),
                    DropdownMenuItem(value: 'marca', child: Text('Marca')),
                    DropdownMenuItem(
                      value: 'categoria',
                      child: Text('Categoría'),
                    ),
                    DropdownMenuItem(value: 'medida', child: Text('Medida')),
                  ],
                  onChanged: (value) {
                    setState(() => _searchField = value ?? 'nombre');
                    _search();
                  },
                ),
              ],
            ],
          ),
        ),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(_error!, textAlign: TextAlign.center),
                TextButton(onPressed: _search, child: const Text('Reintentar')),
              ],
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (widget.employeeMode) {
                return _employeeResults();
              }
              final columns = constraints.maxWidth >= 1000
                  ? 4
                  : constraints.maxWidth >= 600
                  ? 3
                  : 2;
              if (_products.isEmpty && !_loading && _error == null) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_outlined,
                          size: 48,
                          color: Color(0xFF8090A0),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No encontramos productos',
                          style: TextStyle(
                            color: Color(0xFF14283C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text('Prueba con otra búsqueda.'),
                      ],
                    ),
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisExtent: 286,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _products.length,
                itemBuilder: (context, index) => _productCard(_products[index]),
              );
            },
          ),
        ),
      ],
    ),
  );

  Widget _productCard(Product product) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 136,
          width: double.infinity,
          child: ProductPhoto(
            url: product.photoUrl,
            fit: BoxFit.cover,
            iconSize: 48,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                product.brand ?? product.code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 5),
              Text(
                '\$${product.salePrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Color(0xFF14283C),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _addToCart(product),
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('Agregar'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  void _addToCart(Product product) {
    setState(() {
      final current = _cart[product.id];
      _cart[product.id] = OrderCartLine(
        product: product,
        quantity: (current?.quantity ?? 0) + 1,
      );
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${product.name} agregado al carrito'),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  Future<void> _openCart() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderCartScreen(
          items: _cart,
          onCartChanged: () {
            if (mounted) setState(() {});
          },
          onOrderCreated: () {
            if (mounted) setState(_cart.clear);
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _employeeResults() {
    if (_products.isEmpty && !_loading && _error == null) {
      return const Center(child: Text('No se encontraron productos'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.hardware_outlined)),
            title: Text(product.name),
            subtitle: Text(
              '${product.code} · ${product.category ?? 'Sin categoría'}\n'
              'Pasillo ${product.aisle ?? '-'} · Estante ${product.shelf ?? '-'}'
              ' · Nivel ${product.level ?? '-'}\n'
              'Existencia: ${product.stock ?? 0}  |  Mínimo: ${product.minimumStock ?? 0}',
            ),
            isThreeLine: true,
            trailing: Text(
              '\$${product.salePrice.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}

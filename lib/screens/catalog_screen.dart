import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/product.dart';
import '../widgets/product_photo.dart';

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
      title: Text(widget.employeeMode ? 'Búsqueda de productos' : 'Catálogo'),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
              final columns = constraints.maxWidth > 700 ? 3 : 2;
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  childAspectRatio: 0.72,
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
        Expanded(
          child: SizedBox(
            width: double.infinity,
            child: ProductPhoto(
              url: product.photoUrl,
              fit: BoxFit.cover,
              iconSize: 48,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                maxLines: 2,
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
                  color: Color(0xFF37474F),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

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

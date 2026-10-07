class Product {
  const Product({
    required this.id,
    required this.code,
    required this.name,
    required this.salePrice,
    this.brand,
    this.measure,
    this.photoUrl,
    this.purchasePrice,
    this.description,
    this.categoryId,
    this.locationId,
    this.stock,
    this.minimumStock,
    this.category,
    this.aisle,
    this.shelf,
    this.level,
  });

  final int id;
  final String code;
  final String name;
  final double salePrice;
  final String? brand;
  final String? measure;
  final String? photoUrl;
  final double? purchasePrice;
  final String? description;
  final int? categoryId;
  final int? locationId;
  final int? stock;
  final int? minimumStock;
  final String? category;
  final String? aisle;
  final String? shelf;
  final String? level;

  static double? _parseDouble(Object? value, String field) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('El campo "$field" no contiene un número válido.');
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final id = json['id_producto'];
    if (id is! num) {
      throw const FormatException('El producto no contiene un id válido.');
    }
    return Product(
      id: id.toInt(),
      code: json['codigo']?.toString() ?? '',
      name: json['nombre']?.toString() ?? '',
      salePrice: _parseDouble(json['precio_venta'], 'precio_venta') ?? 0,
      brand: json['marca']?.toString(),
      measure: json['medida_presentacion']?.toString(),
      photoUrl: json['fotografia_url']?.toString(),
      purchasePrice: _parseDouble(json['precio_compra'], 'precio_compra'),
      description: json['descripcion']?.toString(),
      categoryId: (json['categoria_id'] as num?)?.toInt(),
      locationId: (json['ubicacion_id'] as num?)?.toInt(),
      stock: (json['stock_actual'] as num?)?.toInt(),
      minimumStock: (json['stock_minimo'] as num?)?.toInt(),
      category: json['categoria']?.toString(),
      aisle: json['pasillo']?.toString(),
      shelf: json['estante']?.toString(),
      level: json['nivel']?.toString(),
    );
  }
}

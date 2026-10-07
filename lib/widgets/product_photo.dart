import 'package:flutter/material.dart';

class ProductPhoto extends StatelessWidget {
  const ProductPhoto({
    required this.url,
    required this.fit,
    this.iconSize = 42,
    super.key,
  });

  final String? url;
  final BoxFit fit;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim();
    if (imageUrl == null || imageUrl.isEmpty) {
      return _placeholder(Icons.hardware_outlined);
    }

    return Image.network(
      imageUrl,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const ColoredBox(
          color: Color(0xFFECEFF1),
          child: Center(
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) =>
          _placeholder(Icons.image_not_supported_outlined),
    );
  }

  Widget _placeholder(IconData icon) => ColoredBox(
    color: const Color(0xFFECEFF1),
    child: Center(
      child: Icon(icon, size: iconSize, color: const Color(0xFF607D8B)),
    ),
  );
}

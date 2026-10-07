import 'package:flutter/material.dart';

import '../core/api_client.dart';
import 'auth_screens.dart';
import 'catalog_screen.dart';
import 'inventory_screen.dart';
import 'pos_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.name,
    required this.email,
    required this.roleId,
    super.key,
  });

  final String name;
  final String email;
  final int roleId;

  String get roleName => switch (roleId) {
        1 => 'Propietario',
        2 => 'Empleado',
        3 => 'Cliente',
        _ => 'Usuario',
      };

  Future<void> _logout(BuildContext context) async {
    await ApiClient.instance.clearToken();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = roleId == 1 || roleId == 2;
    final actions = <_HomeAction>[
      if (roleId == 3)
        _HomeAction(
          'Catálogo de productos',
          'Explora productos y precios',
          Icons.storefront_outlined,
          () => _open(context, const CatalogScreen(employeeMode: false)),
        ),
      if (isStaff) ...[
        _HomeAction(
          'Inventario',
          'Productos, categorías y ubicaciones',
          Icons.inventory_2_outlined,
          () => _open(context, const InventoryScreen()),
        ),
        _HomeAction(
          'Búsqueda de productos',
          'Consulta existencias y pasillos',
          Icons.search,
          () => _open(context, const CatalogScreen(employeeMode: true)),
        ),
        _HomeAction(
          'Punto de venta',
          'Registra una venta y emite factura',
          Icons.point_of_sale,
          () => _open(context, const PosScreen()),
        ),
      ],
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ferretería Bimetálica'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF455A64),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.handyman, color: Colors.white, size: 38),
                  const SizedBox(height: 12),
                  Text(
                    'Hola, $name',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 14),
                  Chip(
                    label: Text(roleName),
                    avatar: const Icon(Icons.badge_outlined, size: 18),
                    backgroundColor: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              '¿Qué necesitas hacer?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (actions.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Tu cuenta no tiene módulos asignados. Contacta al propietario.',
                  ),
                ),
              ),
            ...actions.map(
              (action) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFECEFF1),
                    child: Icon(action.icon, color: const Color(0xFF37474F)),
                  ),
                  title: Text(
                    action.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(action.description),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: action.onTap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _HomeAction {
  const _HomeAction(this.title, this.description, this.icon, this.onTap);

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
}

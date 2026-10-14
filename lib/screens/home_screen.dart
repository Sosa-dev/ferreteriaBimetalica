import 'package:flutter/material.dart';

import '../core/api_client.dart';
import 'auth_screens.dart';
import 'catalog_screen.dart';
import 'inventory_screen.dart';
import 'order_screens.dart';
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
      if (roleId == 3)
        _HomeAction(
          'Mis pedidos',
          'Consulta el estado de tus solicitudes',
          Icons.receipt_long_outlined,
          () => _open(context, const CustomerOrdersScreen()),
        ),
      if (isStaff) ...[
        _HomeAction(
          'Gestión de pedidos',
          'Revisa pedidos y actualiza su estado',
          Icons.assignment_outlined,
          () => _open(context, const StaffOrdersScreen()),
        ),
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
                color: const Color(0xFF14283C),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset('assets/branding/bimetalica_icon.png'),
                  ),
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
                    backgroundColor: const Color(0xFFFFF1E7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              '¿Qué necesitas hacer?',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFEAF0F5),
                    child: Icon(action.icon, color: const Color(0xFF14283C)),
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

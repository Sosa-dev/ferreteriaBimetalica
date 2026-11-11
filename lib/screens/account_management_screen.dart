import 'package:flutter/material.dart';

import '../core/api_client.dart';
import 'auth_screens.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({this.ownerMode = false, super.key});

  final bool ownerMode;

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  final Set<int> _busyUsers = {};
  int? _currentUserId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final usersFuture = ApiClient.instance.dio.get<List<dynamic>>(
        '/usuarios',
      );
      final profileFuture = ApiClient.instance.dio.get<Map<String, dynamic>>(
        '/usuarios/me',
      );
      final usersResponse = await usersFuture;
      final profileResponse = await profileFuture;
      if (!mounted) return;
      setState(() {
        _users = usersResponse.data!
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _currentUserId = (profileResponse.data?['id_usuario'] as num?)?.toInt();
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = ApiClient.instance.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createEmployee() async {
    final employee = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _EmployeeFormDialog(),
    );
    if (employee == null) return;
    try {
      await ApiClient.instance.dio.post(
        '/usuarios',
        data: {
          'Nombres': employee['Nombres'],
          'apellidos': employee['apellidos'],
          'correo': employee['correo'],
          'password': employee['password'],
          'rol_id': 2,
        },
      );
      if (!mounted) return;
      _message('Cuenta de empleado creada.');
      await _loadUsers();
    } catch (error) {
      if (mounted) {
        _message(ApiClient.instance.errorMessage(error), error: true);
      }
    }
  }

  Future<void> _setAccountStatus(Map<String, dynamic> user) async {
    final id = (user['id_usuario'] as num).toInt();
    final active = user['activo'] != true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(active ? 'Activar cuenta' : 'Inactivar cuenta'),
        content: Text(
          active
              ? '¿Permitir que ${user['Nombres']} vuelva a iniciar sesión?'
              : 'La cuenta de ${user['Nombres']} perderá acceso y sus sesiones vigentes se revocarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(active ? 'Activar' : 'Inactivar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !_busyUsers.add(id)) {
      return;
    }
    setState(() {});
    try {
      await ApiClient.instance.dio.put(
        '/usuarios/$id/estado',
        data: {'activo': active},
      );
      if (!mounted) return;
      _message(active ? 'Cuenta activada.' : 'Cuenta inactivada.');
      await _loadUsers();
    } catch (error) {
      if (mounted) {
        _message(ApiClient.instance.errorMessage(error), error: true);
      }
    } finally {
      _busyUsers.remove(id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _revokeUserSessions(Map<String, dynamic> user) async {
    final id = (user['id_usuario'] as num).toInt();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar todas las sesiones'),
        content: Text(
          'Se cerrarán las sesiones activas de ${user['Nombres']}. La cuenta no se inactivará.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesiones'),
          ),
        ],
      ),
    );
    if (confirmed != true || !_busyUsers.add(id)) {
      return;
    }
    setState(() {});
    try {
      await ApiClient.instance.dio.post('/usuarios/$id/logout-all');
      if (id == _currentUserId) {
        await ApiClient.instance.clearToken();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      } else if (mounted) {
        _message('Se cerraron las sesiones de la cuenta.');
      }
    } catch (error) {
      if (mounted) {
        _message(ApiClient.instance.errorMessage(error), error: true);
      }
    } finally {
      _busyUsers.remove(id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _revokeMySessions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar todas mis sesiones'),
        content: const Text(
          'Se revocarán todas tus sesiones. Tendrás que iniciar sesión nuevamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesiones'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await ApiClient.instance.dio.post('/auth/logout-all');
      await ApiClient.instance.clearToken();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (error) {
      if (mounted) {
        _message(ApiClient.instance.errorMessage(error), error: true);
      }
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Cuentas de usuario'),
      actions: [
        if (widget.ownerMode)
          IconButton(
            tooltip: 'Cerrar todas mis sesiones',
            onPressed: _revokeMySessions,
            icon: const Icon(Icons.logout),
          ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _loadUsers,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadUsers,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (widget.ownerMode) ...[
                  FilledButton.icon(
                    onPressed: _createEmployee,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Crear cuenta de empleado'),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'La contraseña se define al crear una cuenta. El correo y la contraseña de cuentas existentes no se editan aquí.',
                  ),
                  const SizedBox(height: 14),
                ],
                if (_users.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('No hay usuarios registrados.'),
                    ),
                  ),
                ..._users.map(_userCard),
              ],
            ),
          ),
  );

  Widget _userCard(Map<String, dynamic> user) {
    final id = (user['id_usuario'] as num).toInt();
    final roleId = (user['rol_id'] as num?)?.toInt() ?? 0;
    final role = switch (roleId) {
      1 => 'Propietario',
      2 => 'Empleado',
      3 => 'Cliente',
      _ => 'Usuario',
    };
    final active = user['activo'] == true;
    final busy = _busyUsers.contains(id);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person_outline)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user['Nombres'] ?? ''} ${user['apellidos'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(user['correo']?.toString() ?? ''),
                    ],
                  ),
                ),
                Chip(
                  label: Text(active ? 'Activo' : 'Inactivo'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('$role · ID $id'),
            if (widget.ownerMode) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: busy || id == _currentUserId
                        ? null
                        : () => _setAccountStatus(user),
                    icon: Icon(
                      active ? Icons.block : Icons.check_circle_outline,
                    ),
                    label: Text(
                      id == _currentUserId
                          ? 'Tu cuenta'
                          : active
                          ? 'Inactivar cuenta'
                          : 'Activar cuenta',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : () => _revokeUserSessions(user),
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesiones'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmployeeFormDialog extends StatefulWidget {
  const _EmployeeFormDialog();

  @override
  State<_EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<_EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Crear cuenta de empleado'),
    content: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_name, 'Nombres'),
            _field(_lastName, 'Apellidos'),
            _field(
              _email,
              'Correo electrónico',
              keyboardType: TextInputType.emailAddress,
              maxLength: 150,
              validator: (value) =>
                  value != null &&
                      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(value.trim())
                  ? null
                  : 'Ingresa un correo válido',
            ),
            _field(
              _password,
              'Contraseña inicial',
              obscureText: true,
              maxLength: 255,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(context, {
            'Nombres': _name.text.trim(),
            'apellidos': _lastName.text.trim(),
            'correo': _email.text.trim(),
            'password': _password.text,
          });
        },
        child: const Text('Crear'),
      ),
    ],
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    bool obscureText = false,
    int? maxLength,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      decoration: InputDecoration(labelText: label),
      validator:
          validator ??
          (value) => value == null || value.trim().isEmpty
              ? 'Este campo es obligatorio'
              : null,
    ),
  );
}

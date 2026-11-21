import 'package:flutter/material.dart';
import '../services/api_service.dart';
import './admin/admin_home_screen.dart';
import './client/client_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();

  String _selectedRole = 'admin'; // 'admin' o 'client'
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _statusMessage;
  bool _isError = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _isError = false;
    });

    final result = await _apiService.login(
        role: _selectedRole,
        identifier: _identifierController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      final role = (result['role'] ?? _selectedRole).toString().toLowerCase();
      final Widget destination = role == 'admin'
          ? AdminHomeScreen(sessionData: result)
          : ClientHomeScreen(sessionData: result);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => destination),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _selectedRole == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('MLI Préstamos'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.account_balance_wallet, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Iniciar Sesión',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isAdmin
                            ? 'Panel de administración de préstamos y cobros'
                            : 'Consulta tu saldo, fechas de pago y opciones',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 20),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'admin',
                            label: Text('Admin'),
                            icon: Icon(Icons.admin_panel_settings),
                          ),
                          ButtonSegment(
                            value: 'client',
                            label: Text('Cliente'),
                            icon: Icon(Icons.person),
                          ),
                        ],
                        selected: {_selectedRole},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _selectedRole = selection.first;
                            _statusMessage = null;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _identifierController,
                        decoration: InputDecoration(
                          labelText: isAdmin ? 'Usuario o correo Admin' : 'Usuario asignado',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa tu usuario';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu contraseña';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Entrar'),
                      ),
                      if (_statusMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isError
                                ? Colors.red.withValues(alpha: 0.1)
                                : Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusMessage!,
                            style: TextStyle(
                              color: _isError ? Colors.red[800] : Colors.green[800],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
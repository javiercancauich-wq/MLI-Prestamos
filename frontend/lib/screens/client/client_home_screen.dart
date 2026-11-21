import 'package:flutter/material.dart';
import '../login_screen.dart';

class ClientHomeScreen extends StatelessWidget {
  final Map<String, dynamic> sessionData;

  const ClientHomeScreen({super.key, required this.sessionData});

  @override
  Widget build(BuildContext context) {
    final name = sessionData['name'] ?? 'Cliente';
    final username = sessionData['username'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Cuenta — MLI Préstamos'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, $name',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (username.toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Usuario: $username',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                  const Divider(height: 24),
                  const Text(
                    'Resumen de préstamo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Aquí conectaremos tu saldo pendiente, total a pagar, fechas de pago acordadas, avisos/mora y opciones de pago.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../login_screen.dart';
import 'new_loan_intake_screen.dart';
import './loans_payments_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  final Map<String, dynamic> sessionData;

  const AdminHomeScreen({super.key, required this.sessionData});

  @override
  Widget build(BuildContext context) {
    final name = sessionData['name'] ?? 'Administrador MLI';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Admin — MLI Préstamos'),
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
                    'Bienvenido, $name',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Registra clientes, sube fotos del INE (frente y reverso), calcula plazos y genera credenciales automáticas.',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NewLoanIntakeScreen(),
                ),
              );
            },
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Nueva Solicitud de Préstamo'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            

            
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LoansPaymentsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.list_alt),
            label: const Text('Ver Préstamos y Abonos en Efectivo'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          
        ],
      ),
    );
  }
}
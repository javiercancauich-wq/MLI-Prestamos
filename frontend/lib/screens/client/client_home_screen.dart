import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  final Map<String, dynamic> sessionData;

  const ClientHomeScreen({super.key, required this.sessionData});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final rawId = widget.sessionData['borrower_id'];
    final borrowerId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    if (borrowerId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No se encontró el ID del cliente en la sesión.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getClientLoanSummary(borrowerId);
      if (!mounted) return;
      setState(() {
        _summary = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatFrequency(String? freq) {
    switch (freq) {
      case 'weekly':
        return 'Semanal';
      case 'monthly':
        return 'Mensual';
      case 'biweekly':
      default:
        return 'Quincenal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _summary?['full_name'] ?? widget.sessionData['name'] ?? 'Cliente';
    final username = _summary?['username'] ?? widget.sessionData['username'] ?? '';
    final schedule = (_summary?['schedule'] as List?) ?? const [];
    final payments = (_summary?['payments'] as List?) ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Cuenta — MLI Préstamos'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _loadSummary,
          ),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _loadSummary,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSummary,
                  child: ListView(
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
                              if (username.toString().isNotEmpty)
                                Text(
                                  'Usuario: $username',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              const Divider(height: 20),
                              Text(
                                'Saldo pendiente: \$${_summary?['remaining_balance'] ?? 0}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text('Total a pagar: \$${_summary?['total_to_pay'] ?? 0}'),
                              Text('Total abonado: \$${_summary?['total_paid'] ?? 0}'),
                              Text(
                                'Cuota: \$${_summary?['installment_amount'] ?? 0} (${_summary?['installments_count'] ?? 0} pagos · ${_formatFrequency(_summary?['frequency']?.toString())})',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Calendario de cuotas',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...schedule.map((item) {
                        final row = item as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${row['installment']}'),
                            ),
                            title: Text('Vence: ${row['due_date']}'),
                            subtitle: Text(
                              'Capital: \$${row['principal']} · Interés: \$${row['interest']}',
                            ),
                            trailing: Text(
                              '\$${row['amount']}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 18),
                      const Text(
                        'Historial de pagos',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (payments.isEmpty)
                        const Text('Aún no hay pagos registrados.')
                      else
                        ...payments.map((p) {
                          final pay = p as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.check_circle_outline),
                              title: Text('Abono: \$${pay['amount']}'),
                              subtitle: Text(
                                'Método: ${pay['payment_method']}${pay['notes'] != null && pay['notes'].toString().isNotEmpty ? ' · ${pay['notes']}' : ''}',
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}
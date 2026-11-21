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

  Future<void> _openPaymentSheet(String method, String methodTitle) async {
    final loanId = _summary?['loan_id'];
    if (loanId == null) return;

    final suggested = (_summary?['installment_amount'] ?? '').toString();
    final amountController = TextEditingController(text: suggested);
    final notesController = TextEditingController(
      text: method == 'cash'
          ? 'Coordinar cobro en efectivo en domicilio'
          : 'Pago reportado vía $methodTitle',
    );
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Pagar con $methodTitle',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      method == 'cash'
                          ? 'El Admin registra los abonos en efectivo en tu domicilio.'
                          : method == 'transfer'
                              ? 'Realiza tu transferencia y reporta el monto abonado.'
                              : 'Completa el monto a abonar con tarjeta.',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Monto a pagar (\$)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Ingresa un monto válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Referencia o nota',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSheetState(() => saving = true);
                              try {
                                await _apiService.registerPayment(
                                  loanId: loanId as int,
                                  amount: double.parse(amountController.text),
                                  paymentMethod: method,
                                  notes: notesController.text,
                                );
                                if (!sheetContext.mounted) return;
                                Navigator.pop(sheetContext);
                                if (!mounted) return;
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '¡Gracias por tu pago! Tu cuenta se ha actualizado.',
                                    ),
                                  ),
                                );
                                await _loadSummary();
                              } catch (e) {
                                setSheetState(() => saving = false);
                                if (!mounted) return;
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.toString().replaceFirst('Exception: ', ''),
                                    ),
                                  ),
                                );
                              }
                            },
                      child: Text(saving ? 'Procesando...' : 'Confirmar pago'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    amountController.dispose();
    notesController.dispose();
  }

  Widget _buildAlertBanner() {
    final status = (_summary?['alert_status'] ?? 'al_corriente').toString();
    final message = (_summary?['alert_message'] ?? '').toString();
    if (message.isEmpty) return const SizedBox.shrink();

    Color bgColor = Colors.blue.withValues(alpha: 0.1);
    Color fgColor = Colors.blue[900]!;
    IconData icon = Icons.event_available;

    if (status == 'en_mora') {
      bgColor = Colors.red.withValues(alpha: 0.12);
      fgColor = Colors.red[900]!;
      icon = Icons.warning_amber_rounded;
    } else if (status == 'liquidado') {
      bgColor = Colors.green.withValues(alpha: 0.12);
      fgColor = Colors.green[900]!;
      icon = Icons.verified;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fgColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fgColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: fgColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
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
                      _buildAlertBanner(),
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
                              if (_summary?['next_due_date'] != null)
                                Text(
                                  'Próxima fecha acordada: ${_summary?['next_due_date']}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Opciones de pago',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                _openPaymentSheet('cash', 'Efectivo en domicilio'),
                            icon: const Icon(Icons.payments_outlined),
                            label: const Text('Efectivo'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                _openPaymentSheet('transfer', 'Transferencia'),
                            icon: const Icon(Icons.account_balance),
                            label: const Text('Transferencia'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                _openPaymentSheet('card', 'Tarjeta'),
                            icon: const Icon(Icons.credit_card),
                            label: const Text('Tarjeta'),
                          ),
                        ],
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
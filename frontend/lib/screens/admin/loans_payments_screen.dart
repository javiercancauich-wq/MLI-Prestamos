import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class LoansPaymentsScreen extends StatefulWidget {
  const LoansPaymentsScreen({super.key});

  @override
  State<LoansPaymentsScreen> createState() => _LoansPaymentsScreenState();
}

class _LoansPaymentsScreenState extends State<LoansPaymentsScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _loans = const [];

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _apiService.getLoans();
      if (!mounted) return;
      setState(() {
        _loans = list;
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

  Future<void> _openCashPaymentDialog(Map<String, dynamic> loan) async {
    final suggestedAmount =
        loan['installment_amount']?.toString() ?? '';
    final amountController = TextEditingController(text: suggestedAmount);
    final notesController = TextEditingController(
      text: 'Cobro en efectivo en domicilio',
    );
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Abono en efectivo — ${loan['full_name']}'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saldo pendiente: \$${loan['remaining_balance']}'),
                    Text('Dirección: ${loan['address']}'),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Monto recibido en efectivo (\$)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Monto inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Nota (opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => saving = true);
                          try {
                            await _apiService.registerPayment(
                              loanId: loan['loan_id'] as int,
                              amount: double.parse(amountController.text),
                              paymentMethod: 'cash',
                              notes: notesController.text,
                            );
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Abono en efectivo registrado'),
                              ),
                            );
                            await _loadLoans();
                          } catch (e) {
                            setDialogState(() => saving = false);
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
                  child: Text(saving ? 'Guardando...' : 'Registrar abono'),
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();
    notesController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Préstamos y Cobros en Efectivo'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _loadLoans,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _loans.isEmpty
                  ? const Center(
                      child: Text('Aún no hay préstamos registrados.'),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLoans,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _loans.length,
                        itemBuilder: (context, index) {
                          final loan = _loans[index] as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${loan['full_name']} (#${loan['loan_id']})',
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          'Saldo: \$${loan['remaining_balance']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Tel: ${loan['phone']} · Usuario: ${loan['username']}'),
                                  Text('Domicilio: ${loan['address']}'),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Total: \$${loan['total_to_pay']} · Abonado: \$${loan['total_paid']} · Cuota: \$${loan['installment_amount']}',
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: () =>
                                          _openCashPaymentDialog(loan),
                                      icon: const Icon(Icons.payments_outlined),
                                      label: const Text(
                                        'Registrar abono en efectivo',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
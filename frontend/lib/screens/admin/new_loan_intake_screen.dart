import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';

class NewLoanIntakeScreen extends StatefulWidget {
  const NewLoanIntakeScreen({super.key});

  @override
  State<NewLoanIntakeScreen> createState() => _NewLoanIntakeScreenState();
}

class _NewLoanIntakeScreenState extends State<NewLoanIntakeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController(text: '5000');
  final _interestController = TextEditingController(text: '80');
  final _installmentsController = TextEditingController(text: '9');

  final _picker = ImagePicker();
  final _apiService = ApiService();

  String _frequency = 'biweekly';
  XFile? _ineFront;
  XFile? _ineBack;
  bool _isSubmitting = false;
  Map<String, dynamic>? _createdResult;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _amountController.dispose();
    _interestController.dispose();
    _installmentsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isFront) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        if (isFront) {
          _ineFront = picked;
        } else {
          _ineBack = picked;
        }
      });
    }
  }

  Future<void> _submitIntake() async {
    if (!_formKey.currentState!.validate()) return;

    if (_ineFront == null || _ineBack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona las fotos del INE (frente y reverso)'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _createdResult = null;
    });

    try {
      final res = await _apiService.createLoanIntake(
        fullName: _nameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        amount: double.parse(_amountController.text),
        interestRate: double.parse(_interestController.text),
        installmentsCount: int.parse(_installmentsController.text),
        frequency: _frequency,
        frontPath: _ineFront!.path,
        backPath: _ineBack!.path,
      );

      setState(() {
        _createdResult = res;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildIneBox({
    required String label,
    required XFile? file,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Column(
          children: [
            if (file != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(file.path),
                  height: 90,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              const Icon(Icons.badge_outlined, size: 36),
            const SizedBox(height: 8),
            Text(
              file != null ? '$label ✓' : 'Subir $label',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borrower = _createdResult?['borrower'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Solicitud — MLI Préstamos'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Datos del solicitante',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Número de teléfono',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Foto del INE (ambos lados)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildIneBox(
                    label: 'INE Frente',
                    file: _ineFront,
                    onTap: () => _pickImage(true),
                  ),
                  const SizedBox(width: 12),
                  _buildIneBox(
                    label: 'INE Reverso',
                    file: _ineBack,
                    onTap: () => _pickImage(false),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Condiciones del préstamo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Cantidad del préstamo (\$)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Ingresa un monto válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _interestController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: '% Interés total',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n < 0) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _installmentsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Número de pagos',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Plazo / Frecuencia',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                  DropdownMenuItem(value: 'biweekly', child: Text('Quincenal')),
                  DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _frequency = val);
                },
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitIntake,
                icon: const Icon(Icons.save),
                label: Text(
                  _isSubmitting ? 'Guardando...' : 'Guardar y Generar Acceso',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              if (_createdResult != null && borrower != null) ...[
                const SizedBox(height: 20),
                Card(
                  color: Colors.green.withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '¡Solicitud registrada! Comparte estas credenciales al cliente:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Usuario: ${borrower['username']}'),
                        Text('Contraseña: ${borrower['initial_password']}'),
                        const Divider(height: 18),
                        Text('Total a pagar: \$${_createdResult!['total_to_pay']}'),
                        Text(
                          'Cuota estimada: \$${_createdResult!['installment_amount']} (${_createdResult!['installments_count']} pagos)',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
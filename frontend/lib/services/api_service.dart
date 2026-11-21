import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Usa http://127.0.0.1:8000 para Windows/Web o http://10.0.2.2:8000 para emulador Android
  static const String baseUrl = 'http://192.168.0.5:8000';

  Future checkHealth() async {
    final uri = Uri.parse('$baseUrl/');
    final response = await http.get(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error al conectar con el servidor (${response.statusCode})');
    }
  }

  Future createLoanIntake({
    required String fullName,
    required String phone,
    required String address,
    required double amount,
    required double interestRate,
    required int installmentsCount,
    required String frequency, // weekly, biweekly, monthly
    required String frontPath,
    required String backPath,
  }) async {
    final uri = Uri.parse('$baseUrl/api/loans/intake');
    final request = http.MultipartRequest('POST', uri)
      ..fields['full_name'] = fullName.trim()
      ..fields['phone'] = phone.trim()
      ..fields['address'] = address.trim()
      ..fields['amount'] = amount.toString()
      ..fields['interest_rate'] = interestRate.toString()
      ..fields['installments_count'] = installmentsCount.toString()
      ..fields['frequency'] = frequency;

    request.files.add(await http.MultipartFile.fromPath('ine_front', frontPath));
    request.files.add(await http.MultipartFile.fromPath('ine_back', backPath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['detail'] ?? 'No se pudo registrar el préstamo');
    }
  }

  Future login({
    required String role, // 'admin' o 'client'
    required String identifier,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'role': role,
        'identifier': identifier.trim(),
        'password': password,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['detail'] ?? 'Credenciales inválidas');
    }
  }

  Future getClientLoanSummary(int borrowerId) async {
    final uri = Uri.parse('$baseUrl/api/loans/client/$borrowerId');
    final response = await http.get(uri);
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['detail'] ?? 'No se pudo cargar el estado del préstamo');
    }
  }

  Future<List<dynamic>> getLoans() async {
    final uri = Uri.parse('$baseUrl/api/loans');
    final response = await http.get(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(
        data is Map && data['detail'] != null
            ? data['detail']
            : 'No se pudieron cargar los préstamos',
      );
    }
  }

  Future registerPayment({
    required int loanId,
    required double amount,
    required String paymentMethod, // 'cash', 'card', 'transfer'
    String notes = '',
  }) async {
    final uri = Uri.parse('$baseUrl/api/loans/$loanId/payments');
    final request = http.MultipartRequest('POST', uri)
      ..fields['amount'] = amount.toString()
      ..fields['payment_method'] = paymentMethod
      ..fields['notes'] = notes.trim();

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['detail'] ?? 'No se pudo registrar el pago');
    }
  }
}
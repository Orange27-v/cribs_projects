import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cribs_arena/constants.dart';

class PaymentService {
  static const Duration _timeout = Duration(seconds: 15);
  final http.Client _client;

  PaymentService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> getPaymentKeys() async {
    final uri = Uri.parse('$kBaseUrl/payment-keys');
    try {
      final response = await _client.get(uri, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      }).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'publicKey': data['publicKey'] as String? ?? '',
          // Secret key no longer returned from backend for security
        };
      } else {
        throw Exception('Failed to get payment keys: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout');
    } catch (e) {
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}

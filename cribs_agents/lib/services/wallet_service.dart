import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cribs_agents/constants.dart';
import 'package:flutter/foundation.dart';
import 'token_storage_service.dart';

/// Service for managing agent wallet operations
class WalletService {
  final String baseUrl = kBaseUrl;
  final TokenStorageService _tokenStorage = TokenStorageService();

  /// Get wallet balance and details
  Future<Map<String, dynamic>> getWallet() async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/agent/wallet'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Get wallet response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'wallet': responseData['data']?['wallet'],
        };
      } else if (response.statusCode == 401) {
        await _tokenStorage.clearToken();
        return {
          'success': false,
          'message': 'Session expired. Please log in again.',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch wallet',
        };
      }
    } catch (e) {
      debugPrint('Error fetching wallet: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Get wallet transaction history
  Future<Map<String, dynamic>> getTransactions({
    int page = 1,
    int perPage = 20,
    String? type,
  }) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      final queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (type != null) 'type': type,
      };

      final uri = Uri.parse('$baseUrl/agent/wallet/transactions')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Get transactions response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'transactions': responseData['data']?['transactions'] ?? [],
          'pagination': responseData['data']?['pagination'],
        };
      } else if (response.statusCode == 401) {
        await _tokenStorage.clearToken();
        return {
          'success': false,
          'message': 'Session expired. Please log in again.',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch transactions',
        };
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Get wallet summary
  Future<Map<String, dynamic>> getSummary() async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/agent/wallet/summary'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Get summary response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else if (response.statusCode == 401) {
        await _tokenStorage.clearToken();
        return {
          'success': false,
          'message': 'Session expired. Please log in again.',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch summary',
        };
      }
    } catch (e) {
      debugPrint('Error fetching summary: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Initialize deposit
  Future<Map<String, dynamic>> initializeDeposit(double amount) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/agent/wallet/deposit/initialize'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode({'amount': amount}),
      );

      debugPrint('Initialize deposit response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to initialize deposit',
        };
      }
    } catch (e) {
      debugPrint('Error initializing deposit: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Verify deposit
  Future<Map<String, dynamic>> verifyDeposit(String reference) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/agent/wallet/deposit/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode({'reference': reference}),
      );

      debugPrint('Verify deposit response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Deposit verified successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to verify deposit',
        };
      }
    } catch (e) {
      debugPrint('Error verifying deposit: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Get current platform fee
  Future<double> getPlatformFee() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/general/platform-fee'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return (responseData['data']?['platform_fee'] ?? 0.0).toDouble();
        }
      }
      return 0.0; // Fallback if API fails
    } catch (e) {
      debugPrint('Error fetching platform fee: $e');
      return 0.0; // Fallback
    }
  }

  /// Get single transaction details
  Future<Map<String, dynamic>> getTransactionDetails(int transactionId) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/agent/wallet/transactions/$transactionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint(
          'Get transaction details response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else if (response.statusCode == 401) {
        await _tokenStorage.clearToken();
        return {
          'success': false,
          'message': 'Session expired. Please log in again.',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              errorData['message'] ?? 'Failed to fetch transaction details',
        };
      }
    } catch (e) {
      debugPrint('Error fetching transaction details: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }
}

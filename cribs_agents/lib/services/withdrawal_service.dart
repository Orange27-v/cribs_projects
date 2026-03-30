import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cribs_agents/constants.dart';
import 'package:flutter/foundation.dart';
import 'token_storage_service.dart';

/// Model for bank information
class Bank {
  final String code;
  final String name;
  final String? slug;

  Bank({
    required this.code,
    required this.name,
    this.slug,
  });

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'],
    );
  }
}

/// Model for saved bank account
class BankAccount {
  final int id;
  final String bankName;
  final String bankCode;
  final String accountNumber; // Masked
  final String accountName;
  final bool isDefault;
  final DateTime? createdAt;

  BankAccount({
    required this.id,
    required this.bankName,
    required this.bankCode,
    required this.accountNumber,
    required this.accountName,
    required this.isDefault,
    this.createdAt,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] ?? 0,
      bankName: json['bank_name'] ?? '',
      bankCode: json['bank_code'] ?? '',
      accountNumber: json['account_number'] ?? '',
      accountName: json['account_name'] ?? '',
      isDefault: json['is_default'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}

/// Model for withdrawal
class Withdrawal {
  final int id;
  final double amount;
  final double fee;
  final double netAmount;
  final String status;
  final String reference;
  final String bankName;
  final String accountNumber;
  final String? failureReason;
  final DateTime? processedAt;
  final DateTime createdAt;

  Withdrawal({
    required this.id,
    required this.amount,
    required this.fee,
    required this.netAmount,
    required this.status,
    required this.reference,
    required this.bankName,
    required this.accountNumber,
    this.failureReason,
    this.processedAt,
    required this.createdAt,
  });

  factory Withdrawal.fromJson(Map<String, dynamic> json) {
    return Withdrawal(
      id: json['id'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      fee: (json['fee'] ?? 0).toDouble(),
      netAmount: (json['net_amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      reference: json['reference'] ?? '',
      bankName: json['bank_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      failureReason: json['failure_reason'],
      processedAt: json['processed_at'] != null
          ? DateTime.tryParse(json['processed_at'])
          : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isPending => status == 'pending' || status == 'processing';
  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';
}

/// Service for managing agent withdrawals and bank accounts
class WithdrawalService {
  final String baseUrl = kBaseUrl;
  final TokenStorageService _tokenStorage = TokenStorageService();

  /// Get list of Nigerian banks
  Future<Map<String, dynamic>> getBanks() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/agent/banks'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint('Get banks response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final banksJson = responseData['data']?['banks'] ?? [];
        final banks = (banksJson as List)
            .map((b) => Bank.fromJson(b as Map<String, dynamic>))
            .toList();

        return {
          'success': true,
          'banks': banks,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch banks',
        };
      }
    } catch (e) {
      debugPrint('Error fetching banks: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Verify bank account
  Future<Map<String, dynamic>> verifyBankAccount({
    required String accountNumber,
    required String bankCode,
  }) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/agent/bank-accounts/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'account_number': accountNumber,
          'bank_code': bankCode,
        }),
      );

      debugPrint('Verify bank response status: ${response.statusCode}');
      debugPrint('Verify bank response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'account_name': responseData['data']?['account_name'] ?? '',
          'account_number':
              responseData['data']?['account_number'] ?? accountNumber,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Account verification failed',
        };
      }
    } catch (e) {
      debugPrint('Error verifying bank account: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Save bank account as transfer recipient
  Future<Map<String, dynamic>> saveBankAccount({
    required String accountNumber,
    required String bankCode,
    required String bankName,
    required String accountName,
  }) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/agent/bank-accounts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'account_number': accountNumber,
          'bank_code': bankCode,
          'bank_name': bankName,
          'account_name': accountName,
        }),
      );

      debugPrint('Save bank response status: ${response.statusCode}');
      debugPrint('Save bank response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Bank account saved successfully',
          'bank_account': responseData['data']?['bank_account'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to save bank account',
        };
      }
    } catch (e) {
      debugPrint('Error saving bank account: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Get saved bank accounts
  Future<Map<String, dynamic>> getBankAccounts() async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/agent/bank-accounts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Get bank accounts response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final accountsJson = responseData['data']?['bank_accounts'] ?? [];
        final accounts = (accountsJson as List)
            .map((a) => BankAccount.fromJson(a as Map<String, dynamic>))
            .toList();

        return {
          'success': true,
          'bank_accounts': accounts,
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
          'message': errorData['message'] ?? 'Failed to fetch bank accounts',
        };
      }
    } catch (e) {
      debugPrint('Error fetching bank accounts: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Delete a saved bank account
  Future<Map<String, dynamic>> deleteBankAccount(int id) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/agent/bank-accounts/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Delete bank account response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Bank account removed successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to remove bank account',
        };
      }
    } catch (e) {
      debugPrint('Error deleting bank account: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Initiate withdrawal
  Future<Map<String, dynamic>> withdraw({
    required double amount,
    required int recipientId,
  }) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/agent/withdraw'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'amount': amount,
          'recipient_id': recipientId,
        }),
      );

      debugPrint('Withdraw response status: ${response.statusCode}');
      debugPrint('Withdraw response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Withdrawal initiated successfully',
          'withdrawal': responseData['data']?['withdrawal'],
          'new_balance': responseData['data']?['new_balance'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Withdrawal failed',
        };
      }
    } catch (e) {
      debugPrint('Error initiating withdrawal: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Get withdrawal history
  Future<Map<String, dynamic>> getWithdrawals({
    int page = 1,
    int perPage = 20,
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
      };

      final uri = Uri.parse('$baseUrl/agent/withdrawals')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Get withdrawals response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final withdrawalsJson = responseData['data']?['withdrawals'] ?? [];
        final withdrawals = (withdrawalsJson as List)
            .map((w) => Withdrawal.fromJson(w as Map<String, dynamic>))
            .toList();

        return {
          'success': true,
          'withdrawals': withdrawals,
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
          'message': errorData['message'] ?? 'Failed to fetch withdrawals',
        };
      }
    } catch (e) {
      debugPrint('Error fetching withdrawals: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }
}

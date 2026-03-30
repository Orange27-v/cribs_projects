import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/services/token_storage_service.dart';
import 'package:flutter/foundation.dart';

class LeadsService {
  final TokenStorageService _tokenStorage = TokenStorageService();
  final String baseUrl = kBaseUrl;

  Future<Map<String, dynamic>> fetchLeads() async {
    try {
      final token = await _tokenStorage.getToken();

      if (token == null) {
        return {'success': false, 'message': 'Authentication token not found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/agent/leads'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch leads: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error fetching leads: $e');
      return {
        'success': false,
        'message': 'An error occurred while fetching leads'
      };
    }
  }

  /// Fetch followers (users who saved this agent)
  Future<Map<String, dynamic>> fetchFollowers() async {
    try {
      final token = await _tokenStorage.getToken();

      if (token == null) {
        return {'success': false, 'message': 'Authentication token not found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/agent/followers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch followers: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error fetching followers: $e');
      return {
        'success': false,
        'message': 'An error occurred while fetching followers'
      };
    }
  }
}

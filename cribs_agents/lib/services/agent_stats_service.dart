import 'package:cribs_agents/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_storage_service.dart';

/// Service for fetching agent dashboard statistics
class AgentStatsService {
  static final String baseUrl = kAgentBaseUrl;
  static final TokenStorageService _tokenService = TokenStorageService();

  /// Result class for stats operations
  static Future<Map<String, dynamic>> getAgentStats() async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'No authentication token found',
          'sessionExpired': true,
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return {
            'success': true,
            'data': AgentStats.fromJson(data['data']),
          };
        } else {
          return {
            'success': false,
            'error': data['message'] ?? 'Failed to fetch statistics',
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Session expired',
          'sessionExpired': true,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch statistics (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }
}

/// Model class for agent statistics data
class AgentStats {
  final String averageRating;
  final int totalReviews;
  final int closedDeals;
  final int totalClients;
  final int totalListings;
  final int totalLeads;
  final int totalAppointments;

  AgentStats({
    required this.averageRating,
    required this.totalReviews,
    required this.closedDeals,
    required this.totalClients,
    required this.totalListings,
    required this.totalLeads,
    required this.totalAppointments,
  });

  factory AgentStats.fromJson(Map<String, dynamic> json) {
    return AgentStats(
      averageRating: json['average_rating']?.toString() ?? '0.0',
      totalReviews: json['total_reviews'] ?? 0,
      closedDeals: json['closed_deals'] ?? 0,
      totalClients: json['total_clients'] ?? 0,
      totalListings: json['total_listings'] ?? 0,
      totalLeads: json['total_leads'] ?? 0,
      totalAppointments: json['total_appointments'] ?? 0,
    );
  }
}

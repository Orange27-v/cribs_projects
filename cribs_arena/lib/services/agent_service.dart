import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cribs_arena/services/auth_service.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'package:cribs_arena/models/agent.dart';

class AgentService {
  static final String _baseUrl = kBaseUrl;
  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;
  final AuthService _authService = AuthService();

  AgentService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Agent>> findNearbyAgents(
    double lat,
    double lon,
    double radius,
  ) async {
    final uri = Uri.parse('$_baseUrl/agents/nearby').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'radius': radius.toString(),
      },
    );

    return _fetchAgents(uri, 'nearby agents');
  }

  Future<List<Agent>> getAllAgents() async {
    final uri = Uri.parse('$_baseUrl/agents');
    return _fetchAgents(uri, 'all agents');
  }

  Future<Agent> getAgentById(int agentId) async {
    final uri = Uri.parse('$_baseUrl/agents/$agentId');
    final token = await _authService.getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final response =
          await _client.get(uri, headers: headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        // The response for a single agent might be wrapped in a 'data' key
        final agentJson =
            decoded is Map<String, dynamic> && decoded.containsKey('data')
                ? decoded['data']
                : decoded;

        if (agentJson is Map<String, dynamic>) {
          return Agent.fromJson(agentJson);
        } else {
          throw Exception('Invalid agent data format');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Agent not found');
      } else {
        throw Exception('Failed to load agent: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to load agent: $e');
    }
  }

  Future<List<Agent>> _fetchAgents(Uri uri, String context) async {
    http.Response? response;
    final token = await _authService.getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      response = await _client.get(uri, headers: headers).timeout(_timeout);

      if (response.statusCode == 200) {
        return _parseAgentsResponse(response.body, context);
      } else {
        throw Exception('Failed to load $context: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to load $context: $e');
    }
  }

  List<Agent> _parseAgentsResponse(String responseBody, String context) {
    try {
      final dynamic decoded = jsonDecode(responseBody);

      // Case 1: Bare list [ {..agent..}, ... ]
      if (decoded is List) {
        return decoded
            .where((item) => item != null && item is Map<String, dynamic>)
            .map((item) => Agent.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response format');
      }

      final Map<String, dynamic> json = decoded;

      // Optional status check (do not require it)
      if (json.containsKey('status') && json['status'] is String) {
        if (json['status'] != 'success') {
          final message = json['message'];
          throw Exception(
              message is String ? message : 'Failed to load $context');
        }
      }

      // Extract data -> agents
      final dynamic data = json.containsKey('data') ? json['data'] : json;
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid data format');
      }

      final dynamic agentsList =
          data['agents'] ?? data['data'] ?? data['results'];
      if (agentsList == null) {
        return [];
      }

      if (agentsList is! List) {
        throw Exception('Invalid agents data format');
      }

      return agentsList
          .where((item) => item != null && item is Map<String, dynamic>)
          .map((item) => Agent.fromJson(item as Map<String, dynamic>))
          .toList();
    } on FormatException {
      throw Exception('Failed to parse response');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error parsing agents: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

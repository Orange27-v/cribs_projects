import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/services/auth_service.dart';
import 'package:cribs_arena/models/agent.dart';

class SavedAgentService {
  static final String _baseUrl = kUserBaseUrl;
  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;
  final AuthService _authService = AuthService();

  SavedAgentService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Agent>> getSavedAgents() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$_baseUrl/saved-agents');
    final res =
        await _client.get(uri, headers: _headers(token)).timeout(_timeout);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic> && data['status'] == 'success') {
        final payload = data['data'];

        List<dynamic>? agentsData;
        if (payload is Map<String, dynamic> && payload.containsKey('data')) {
          agentsData = payload['data'];
        } else if (payload is Map<String, dynamic> &&
            payload.containsKey('agents')) {
          agentsData = payload['agents'];
        } else if (payload is List) {
          agentsData = payload;
        }

        if (agentsData is List) {
          return agentsData
              .where((e) => e != null && e is Map<String, dynamic>)
              .map((e) => Agent.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    }

    String errorBody = res.body.isNotEmpty ? res.body : '(empty body)';
    throw Exception(
        'Failed to load saved agents: ${res.statusCode} - $errorBody');
  }

  Future<bool> isAgentSaved(String agentId) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    final uri = Uri.parse('$_baseUrl/agents/$agentId/is-saved');
    final res =
        await _client.get(uri, headers: _headers(token)).timeout(_timeout);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic> && data['status'] == 'success') {
        return data['data']['is_saved'] ?? false;
      }
    }
    return false;
  }

  Future<void> saveAgent(String agentId) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$_baseUrl/agents/$agentId/save');
    final res =
        await _client.post(uri, headers: _headers(token)).timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to save agent: ${res.body}');
    }
  }

  Future<void> unsaveAgent(String agentId) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$_baseUrl/agents/$agentId/unsave');
    final res =
        await _client.delete(uri, headers: _headers(token)).timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to unsave agent: ${res.body}');
    }
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Stream that periodically emits the total count of saved agents
  Stream<int> getSavedAgentsCountStream(
      {Duration interval = const Duration(seconds: 5)}) {
    return Stream.periodic(interval).asyncMap((_) async {
      try {
        final agents = await getSavedAgents();
        return agents.length;
      } catch (e) {
        return 0;
      }
    });
  }

  void dispose() => _client.close();
}

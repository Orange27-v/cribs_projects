import 'dart:convert';
import 'dart:async';
import 'package:cribs_arena/models/agent.dart';
import 'package:http/http.dart' as http;
import 'package:cribs_arena/constants.dart';

class ApiService {
  static final String _baseUrl = kBaseUrl;

  Future<List<Agent>> getAgents(double latitude, double longitude) async {
    final uri = Uri.parse(
      '$_baseUrl/agents/nearby?lat=$latitude&lon=$longitude&radius=10',
    );

    int retries = 0;
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 2);

    while (true) {
      try {
        final response =
            await http.get(uri).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);

          if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
            final data = decoded['data'];
            if (data is Map<String, dynamic> && data.containsKey('agents')) {
              final agentsData = data['agents'];
              if (agentsData is List) {
                return agentsData
                    .whereType<Map<String, dynamic>>()
                    .map((agentJson) => Agent.fromJson(agentJson))
                    .toList();
              } else {
                throw Exception('Invalid agents data type');
              }
            } else {
              throw Exception('Invalid data format');
            }
          } else {
            throw Exception('Unexpected response format');
          }
        } else {
          throw Exception('Failed to load agents: ${response.statusCode}');
        }
      } on TimeoutException {
        if (retries < maxRetries) {
          retries++;
          await Future.delayed(retryDelay);
          continue;
        } else {
          throw Exception('Request timed out after multiple retries.');
        }
      } catch (e) {
        if (retries < maxRetries) {
          retries++;
          await Future.delayed(retryDelay);
          continue;
        } else {
          throw Exception(
              'Failed to fetch agents. Check your internet connection.');
        }
      }
    }
  }
}

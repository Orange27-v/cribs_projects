import 'dart:convert';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/models/client.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ClientService {
  Future<List<Client>> getClients() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(kAuthTokenKey);

    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$kAgentBaseUrl/clients'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        final List<dynamic> clientsJson = data['data'];
        return clientsJson.map((json) => Client.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load clients');
      }
    } else {
      throw Exception('Failed to load clients: ${response.statusCode}');
    }
  }
}

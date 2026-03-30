import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cribs_arena/constants.dart';

class UserService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kAuthTokenKey);
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final uri = Uri.parse('$kUserBaseUrl/profile');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user profile: ${response.reasonPhrase}');
    }
  }

  Future<Map<String, dynamic>> updateUserProfile({
    String? name,
    String? phone,
    String? location,
    File? imageFile,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final uri = Uri.parse('$kUserBaseUrl/profile/update');
    var request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    // Add text fields if provided
    if (name != null) request.fields['name'] = name;
    if (phone != null) request.fields['phone'] = phone;
    if (location != null) request.fields['location'] = location;
    // Add a hidden method field to tell Laravel we are doing a PUT/PATCH request
    request.fields['_method'] = 'PUT';

    // Add image file if it exists
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_picture',
          imageFile.path,
        ),
      );
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(responseBody);
    } else {
      throw Exception(
          'Failed to update profile: ${response.reasonPhrase} - $responseBody');
    }
  }

  Future<void> updatePassword(String currentPassword, String newPassword,
      String passwordConfirmation) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final uri = Uri.parse('$kUserBaseUrl/password');
    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': passwordConfirmation,
      }),
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(
          errorBody['message'] ?? 'Failed to update backend password.');
    }
  }

  Future<Map<String, dynamic>> fetchAgentDetails(String agentId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final uri = Uri.parse('$kBaseUrl/agents/$agentId');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(
          'Failed to load agent details: ${errorBody['message'] ?? response.reasonPhrase}');
    }
  }

  void dispose() {
    // No resources to dispose in this version
  }
}

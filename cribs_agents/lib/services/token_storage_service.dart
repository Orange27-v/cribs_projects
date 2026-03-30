import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for managing authentication tokens in local storage
class TokenStorageService {
  static const String _authTokenKey = 'auth_token';

  /// Save authentication token to local storage
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
  }

  /// Retrieve authentication token from local storage
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  /// Clear authentication token from local storage
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
  }

  /// Check if user is logged in (has a valid token)
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}

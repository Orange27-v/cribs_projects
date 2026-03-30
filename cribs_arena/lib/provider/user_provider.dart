import 'package:cribs_arena/services/user_auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  dynamic _user;
  String? _paystackPublicKey;
  String? _paystackSecretKey;
  bool _isLoading = false;
  String? _error;

  final UserAuthService _authService = UserAuthService();

  dynamic get user => _user;
  String? get paystackPublicKey => _paystackPublicKey;
  String? get paystackSecretKey => _paystackSecretKey;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUserProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.fetchUserData();
      if (result['success'] == true && result['data'] != null) {
        _user = result['data'];
        _error = null;
      } else {
        _error = result['message'] ?? 'Failed to load profile';
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching user profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setUser(dynamic user) {
    _user = user;
    notifyListeners();
  }

  void setPaymentKeys(String publicKey, String secretKey) {
    _paystackPublicKey = publicKey;
    _paystackSecretKey = secretKey;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    _paystackPublicKey = null;
    _paystackSecretKey = null;
    notifyListeners();
  }

  void updateUser(dynamic user) {
    _user = user;
    notifyListeners();
  }

  void updateProfilePicture(String newImageUrl) {
    if (_user != null) {
      _user['profile_picture_url'] = newImageUrl;
      notifyListeners();
    }
  }

  // Check if user is verified
  bool get isVerified {
    if (_user == null) return false;
    // For cribs_users, check nin_verification or bvn_verification
    return (_user['nin_verification'] ?? 0) > 0 ||
        (_user['bvn_verification'] ?? 0) > 0;
  }

  String get createdAt {
    if (_user == null) return '';
    return _user['created_at'] ?? '';
  }

  // Get user full name
  String get fullName {
    if (_user == null) return 'User';
    return '${_user['first_name']} ${_user['last_name']}';
  }

  // Get user email
  String get email => _user?['email'] ?? '';

  // Get user area
  String? get area => _user?['area'];

  // Check if user data is loaded
  bool get hasUser => _user != null;
}

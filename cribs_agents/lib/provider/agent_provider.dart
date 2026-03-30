import 'package:flutter/material.dart';
import 'package:cribs_agents/services/auth_service.dart';

class Agent {
  final int id;
  final int agentId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? area;
  final String? role;
  final String? profilePictureUrl;
  final String? agreedToTermsVersion;
  final DateTime? createdAt;

  final bool isFaceVerified;
  final bool isAddressVerified;
  final bool isNinVerified;
  final bool isBvnVerified;

  Agent({
    required this.id,
    required this.agentId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.area,
    this.role,
    this.profilePictureUrl,
    this.agreedToTermsVersion,
    this.createdAt,
    this.isFaceVerified = false,
    this.isAddressVerified = false,
    this.isNinVerified = false,
    this.isBvnVerified = false,
  });

  String get fullName => '$firstName $lastName';

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] ?? 0,
      agentId: json['agent_id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      area: json['area'],
      role: json['role'],
      profilePictureUrl: json['profile_picture_url'],
      agreedToTermsVersion: json['agreed_to_terms_version'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      isFaceVerified:
          json['is_face_verified'] == 1 || json['is_face_verified'] == true,
      isAddressVerified: json['is_address_verified'] == 1 ||
          json['is_address_verified'] == true,
      isNinVerified: json['nin_verification'] == 1 ||
          json['nin_verification'] == true ||
          json['is_nin_verified'] == 1 ||
          json['is_nin_verified'] == true,
      isBvnVerified: json['bvn_verification'] == 1 ||
          json['bvn_verification'] == true ||
          json['is_bvn_verified'] == 1 ||
          json['is_bvn_verified'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agent_id': agentId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'area': area,
      'role': role,
      'profile_picture_url': profilePictureUrl,
      'agreed_to_terms_version': agreedToTermsVersion,
      'created_at': createdAt?.toIso8601String(),
      'is_face_verified': isFaceVerified,
      'is_address_verified': isAddressVerified,
      'is_nin_verified': isNinVerified,
      'is_bvn_verified': isBvnVerified,
    };
  }
}

class AgentProvider with ChangeNotifier {
  Agent? _agent;
  bool _isLoading = false;
  String? _error;

  final AuthService _authService = AuthService();

  Agent? get agent => _agent;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasAgent => _agent != null;

  /// Fetch agent profile from the backend
  Future<void> fetchAgentProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.getProfile();

      if (result['success'] == true && result['data'] != null) {
        _agent = Agent.fromJson(result['data']);
        _error = null;
      } else {
        _error = result['message'] ?? 'Failed to load profile';
        _agent = null;
      }
    } catch (e) {
      _error = 'An error occurred: ${e.toString()}';
      _agent = null;
      debugPrint('Error fetching agent profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set agent data manually (e.g., after login)
  void setAgent(Agent agent) {
    _agent = agent;
    _error = null;
    notifyListeners();
  }

  /// Update agent data
  void updateAgent(Agent agent) {
    _agent = agent;
    notifyListeners();
  }

  /// Clear agent data (e.g., on logout)
  void clearAgent() {
    _agent = null;
    _error = null;
    notifyListeners();
  }

  /// Refresh agent profile
  Future<void> refreshProfile() async {
    await fetchAgentProfile();
  }

  /// Check if agent is verified (NIN or BVN)
  bool get isVerified {
    if (_agent == null) return false;
    return _agent!.isNinVerified || _agent!.isBvnVerified;
  }
}

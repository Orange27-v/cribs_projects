import 'package:cribs_arena/constants.dart';

class ChatHelper {
  /// Constructs complete chat data for MongoDB conversation creation
  static Map<String, dynamic> constructChatData({
    required Map<String, dynamic> user,
    required Map<String, dynamic> agent,
    String? initialMessage,
    String? propertyTitle,
    String? inspectionDate,
    String? inspectionTime,
  }) {
    return {
      'userId': 'user_${user['user_id']}',
      'agentId': 'agent_${agent['agent_id']}',
      'userName':
          '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim(),
      'userAvatar': _getFullImageUrl(user['profile_picture_url']),
      'agentName':
          '${agent['first_name'] ?? ''} ${agent['last_name'] ?? ''}'.trim(),
      'agentAvatar': _getFullImageUrl(
          agent['profile_image'] ?? agent['profile_picture_url']),
      'initialMessage': initialMessage ??
          _generateDefaultMessage(
            propertyTitle: propertyTitle,
            inspectionDate: inspectionDate,
            inspectionTime: inspectionTime,
          ),
      'tags': [
        if (propertyTitle != null && propertyTitle.isNotEmpty)
          'Property Inquiry: $propertyTitle',
        if (inspectionDate != null) 'Booking Inquiry',
      ],
    };
  }

  /// Converts relative image URL to full URL
  static String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';

    // Already a full URL
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Remove leading slash if present
    String cleanUrl = url.startsWith('/') ? url.substring(1) : url;

    // If it's already a full storage path (e.g., "storage/profile_pictures/1.jpg")
    if (cleanUrl.startsWith('storage/')) {
      return '$kMainBaseUrl$cleanUrl';
    }

    // If it's a relative path like "profile_pictures/xxx.jpg" or "agent_pictures/xxx.jpg"
    if (cleanUrl.contains('profile_pictures/') ||
        cleanUrl.contains('agent_pictures/') ||
        cleanUrl.contains('user_pictures/') ||
        cleanUrl.contains('property_images/')) {
      return '${kMainBaseUrl}storage/$cleanUrl';
    }

    // fallback for any other relative path that might need storage
    return '${kMainBaseUrl}storage/$cleanUrl';
  }

  /// Public method to convert relative image URL to full URL
  static String getFullImageUrl(String? url) {
    return _getFullImageUrl(url);
  }

  /// Generates a default initial message based on context
  static String _generateDefaultMessage({
    String? propertyTitle,
    String? inspectionDate,
    String? inspectionTime,
  }) {
    if (propertyTitle != null && propertyTitle.isNotEmpty) {
      return "Hi, I'm interested in $propertyTitle. Can we discuss the details?";
    }

    if (inspectionDate != null && inspectionTime != null) {
      return "Hi, regarding our scheduled inspection on $inspectionDate at $inspectionTime...";
    }

    return "Hi, I'd like to know more about your available properties.";
  }

  /// Validates chat data before sending to server
  static bool validateChatData(Map<String, dynamic> chatData) {
    return chatData['userId'] != null &&
        chatData['agentId'] != null &&
        chatData['userName'] != null &&
        chatData['agentName'] != null &&
        chatData['userId'].toString().isNotEmpty &&
        chatData['agentId'].toString().isNotEmpty;
  }

  /// Extracts agent data from different formats
  static Map<String, dynamic> extractAgentData(dynamic agentData) {
    if (agentData is Map<String, dynamic>) {
      return agentData;
    }
    return {};
  }

  /// Formats date for display in messages
  static String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

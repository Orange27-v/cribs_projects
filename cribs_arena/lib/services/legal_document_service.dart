import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cribs_arena/constants.dart';
import 'package:flutter/foundation.dart';

class LegalDocumentService {
  static final String _baseUrl = kBaseUrl;

  Future<String> getLegalDocument(String type) async {
    debugPrint('Fetching legal document from: $_baseUrl/legal/$type');
    final response = await http.get(Uri.parse('$_baseUrl/legal/$type'));
    debugPrint('Response status code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      debugPrint('Response body: ${response.body}');

      // Check for various possible response structures
      if (data is Map<String, dynamic>) {
        if (data['status'] == 'success') {
          final contentData = data['data'];
          if (contentData is Map<String, dynamic>) {
            // Safely access 'content' and provide a default if null
            return contentData['content']?.toString() ?? '';
          } else if (contentData is String) {
            return contentData;
          }
        }
        // Safely check for 'content' key directly at the top level
        if (data.containsKey('content')) {
          return data['content']?.toString() ?? '';
        }
      }
      // If data is a string directly, return it, or an empty string if null
      if (data is String) {
        return data;
      }

      debugPrint(
          'Failed to parse legal document: Unexpected format for type $type');
      // Return an empty string as a fallback instead of throwing an exception
      return '';
    } else {
      debugPrint(
          'Failed to load legal document for type $type (Status code: ${response.statusCode})');
      throw Exception(
          'Failed to load legal document (Status code: ${response.statusCode})');
    }
  }
}

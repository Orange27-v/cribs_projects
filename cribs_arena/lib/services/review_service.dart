import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cribs_arena/services/auth_service.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class ReviewService {
  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;
  final AuthService _authService = AuthService();

  ReviewService({http.Client? client}) : _client = client ?? http.Client();

  Future<http.Response> submitReview({
    required int agentId,
    required int rating,
    required String reviewText,
  }) async {
    final uri = Uri.parse('$kUserBaseUrl/agents/$agentId/reviews');
    final token = await _authService.getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final body = jsonEncode({
      'rating': rating.toString(),
      'review_text': reviewText,
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(_timeout);
      return response;
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout');
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }

  Future<http.Response> submitReport({
    required int agentId,
    required String issue,
    String? details,
  }) async {
    final uri = Uri.parse('$kUserBaseUrl/agents/$agentId/reports');
    final token = await _authService.getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final body = jsonEncode({
      'issue': issue,
      'details': details,
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(_timeout);
      return response;
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout');
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }

  Future<List<dynamic>> getAgentReviews(int agentId) async {
    final uri = Uri.parse('$kBaseUrl/agents/$agentId/reviews');
    final token = await _authService.getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final response =
          await _client.get(uri, headers: headers).timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return []; // Return an empty list if no reviews are found
      } else {
        throw Exception('Failed to load reviews');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timeout');
    } catch (e) {
      throw Exception('Failed to load reviews: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

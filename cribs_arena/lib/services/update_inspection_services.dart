import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:cribs_arena/constants.dart';

class UpdateInspectionService {
  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const int _baseDelaySeconds = 2;

  final http.Client _client;
  String? _cachedToken;

  UpdateInspectionService({http.Client? client})
      : _client = client ?? http.Client();

  Future<String?> _getToken() async {
    if (_cachedToken != null) return _cachedToken;

    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(kAuthTokenKey);
    return _cachedToken;
  }

  void clearTokenCache() {
    _cachedToken = null;
  }

  Future<http.Response> _request(
    String url, {
    String method = 'POST',
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final uri = Uri.parse(url);
    final token = authenticated ? await _getToken() : null;

    if (authenticated && token == null) {
      throw Exception('Authentication token not found');
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (authenticated && token != null) 'Authorization': 'Bearer $token',
    };

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await _makeRequest(uri, method, headers, body);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }

        if (response.statusCode == 429 && attempt < _maxRetries - 1) {
          await Future.delayed(
              Duration(seconds: _baseDelaySeconds * (attempt + 1)));
          continue;
        }

        if (response.statusCode == 401) {
          clearTokenCache();
          throw Exception('Unauthorized: Please login again');
        }

        throw Exception(
            'Request failed (${response.statusCode}): ${response.body}');
      } on SocketException {
        if (attempt == _maxRetries - 1) {
          throw Exception('No internet connection');
        }
        await Future.delayed(
            Duration(seconds: _baseDelaySeconds * (attempt + 1)));
      } on TimeoutException {
        if (attempt == _maxRetries - 1) {
          throw Exception('Request timeout');
        }
        await Future.delayed(
            Duration(seconds: _baseDelaySeconds * (attempt + 1)));
      } catch (e) {
        if (attempt == _maxRetries - 1) {
          rethrow;
        }
        await Future.delayed(
            Duration(seconds: _baseDelaySeconds * (attempt + 1)));
      }
    }

    throw Exception('Too many failed attempts for $url');
  }

  Future<http.Response> _makeRequest(
    Uri uri,
    String method,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) async {
    switch (method.toUpperCase()) {
      case 'GET':
        return await _client.get(uri, headers: headers).timeout(_timeout);
      case 'POST':
        return await _client
            .post(uri,
                headers: headers, body: body != null ? jsonEncode(body) : null)
            .timeout(_timeout);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  Future<http.Response> _updateInspectionStatus(
    int inspectionId,
    String status, {
    String? cancellationReason,
    DateTime? rescheduleDate,
    TimeOfDay? rescheduleTime,
  }) async {
    final body = <String, dynamic>{
      'status': status,
    };

    if (cancellationReason != null) {
      body['reason_cancellation'] = cancellationReason;
    }

    if (rescheduleDate != null) {
      body['reschedule_date'] = rescheduleDate.toIso8601String().split('T')[0];
    }

    if (rescheduleTime != null) {
      body['reschedule_time'] =
          '${rescheduleTime.hour.toString().padLeft(2, '0')}:${rescheduleTime.minute.toString().padLeft(2, '0')}';
    }

    // FIX: Use kUserBaseUrl instead of kAgentBaseUrl for user-initiated actions
    return await _request(
      '$kUserBaseUrl/inspections/$inspectionId/status',
      body: body,
    );
  }

  Future<void> rescheduleInspection({
    required int inspectionId,
    required DateTime newDate,
    required TimeOfDay newTime,
  }) async {
    await _updateInspectionStatus(
      inspectionId,
      'rescheduled',
      rescheduleDate: newDate,
      rescheduleTime: newTime,
    );
  }

  Future<void> completeInspection({required int inspectionId}) async {
    await _updateInspectionStatus(inspectionId, 'completed');
  }

  Future<void> cancelInspection({
    required int inspectionId,
    required String reason,
  }) async {
    await _updateInspectionStatus(
      inspectionId,
      'cancelled',
      cancellationReason: reason,
    );
  }

  void dispose() {
    _client.close();
    clearTokenCache();
  }
}

import 'package:cribs_agents/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_storage_service.dart';

/// Service for fetching agent reviews
class AgentReviewService {
  static final String baseUrl = kAgentBaseUrl;
  static final TokenStorageService _tokenService = TokenStorageService();

  /// Fetch reviews for the authenticated agent
  static Future<Map<String, dynamic>> getMyReviews() async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'No authentication token found',
          'sessionExpired': true,
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/reviews'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return {
            'success': true,
            'data': AgentReviewData.fromJson(data['data']),
          };
        } else {
          return {
            'success': false,
            'error': data['message'] ?? 'Failed to fetch reviews',
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Session expired',
          'sessionExpired': true,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch reviews (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }
}

/// Model class for agent review data
class AgentReviewData {
  final List<Review> reviews;
  final Map<String, int> ratingBreakdown;
  final String averageRating;
  final int totalReviews;
  final String agentName;
  final String? agentImage;
  final String agentLocation;

  AgentReviewData({
    required this.reviews,
    required this.ratingBreakdown,
    required this.averageRating,
    required this.totalReviews,
    required this.agentName,
    this.agentImage,
    required this.agentLocation,
  });

  factory AgentReviewData.fromJson(Map<String, dynamic> json) {
    final reviewsList = (json['reviews'] as List? ?? [])
        .map((r) => Review.fromJson(r as Map<String, dynamic>))
        .toList();

    final ratingMap = <String, int>{};
    final breakdown = json['rating_breakdown'];
    if (breakdown is Map) {
      breakdown.forEach((key, value) {
        ratingMap[key.toString()] =
            (value is int) ? value : int.tryParse(value.toString()) ?? 0;
      });
    }

    return AgentReviewData(
      reviews: reviewsList,
      ratingBreakdown: ratingMap,
      averageRating: json['average_rating']?.toString() ?? '0.0',
      totalReviews: (json['total_reviews'] is int)
          ? json['total_reviews']
          : int.tryParse(json['total_reviews']?.toString() ?? '0') ?? 0,
      agentName: json['agent_name']?.toString() ?? '',
      agentImage: json['agent_image']?.toString(),
      agentLocation: json['agent_location']?.toString() ?? '',
    );
  }
}

/// Model class for individual review
class Review {
  final int id;
  final String reviewerName;
  final String? reviewerImage;
  final String? reviewText;
  final int rating;
  final DateTime? createdAt;

  Review({
    required this.id,
    required this.reviewerName,
    this.reviewerImage,
    this.reviewText,
    required this.rating,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: (json['id'] is int)
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      reviewerName: json['reviewer_name']?.toString() ?? 'Anonymous',
      reviewerImage: json['reviewer_image']?.toString(),
      reviewText: json['review_text']?.toString(),
      rating: (json['rating'] is int)
          ? json['rating']
          : int.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

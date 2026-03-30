import 'package:flutter/foundation.dart';
import 'dart:convert';

class Agent {
  final int id;
  final String agentId;
  final String? userId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? area;
  final String? role;
  final double? latitude;
  final double? longitude;
  final int? loginStatus;
  final String? profilePictureUrl;
  final List<String>? activeAreas;
  final int? totalSales;
  final double? averageRating;
  final int? totalReviews;
  final String? memberSince;
  final String? bio;
  final double? bookingFees;
  final bool? isLicensed;
  final int? experienceYears;

  const Agent({
    required this.id,
    required this.agentId,
    this.userId,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.area,
    this.role,
    this.latitude,
    this.longitude,
    this.loginStatus,
    this.profilePictureUrl,
    this.activeAreas,
    this.totalSales,
    this.averageRating,
    this.totalReviews,
    this.memberSince,
    this.bio,
    this.bookingFees,
    this.isLicensed,
    this.experienceYears,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v, {int fallback = 0}) {
      if (v == null) {
        return fallback;
      }
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      if (v is bool) return v ? 1 : 0;
      debugPrint(
          'Agent.toInt: Unexpected type ${v.runtimeType} for int, using fallback $fallback');
      return fallback;
    }

    double? toDouble(dynamic v) => v is double
        ? v
        : (v is num ? v.toDouble() : double.tryParse(v?.toString() ?? ''));

    bool? toBool(dynamic v) {
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String) {
        return v.toLowerCase() == 'true' || v.toLowerCase() == '1';
      }
      return null;
    }

    List<String>? toStringList(dynamic v) {
      if (v == null) return null;
      if (v is List) {
        return v
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      if (v is String) {
        if (v.trim().isEmpty) return null;
        try {
          final decoded = jsonDecode(v);
          if (decoded is List) {
            return decoded
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }
        } catch (e) {
          debugPrint('Failed to parse as JSON, trying comma split: $e');
        }
        return v
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return null;
    }

    final information = json['information'] as Map<String, dynamic>?;

    return Agent(
      id: toInt(json['id']),
      agentId: json['agent_id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      area: json['area']?.toString(),
      role: json['role']?.toString(),
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
      loginStatus: toInt(json['login_status']),
      profilePictureUrl: information?['profile_picture_url']?.toString(),
      activeAreas: toStringList(information?['active_areas']),
      totalSales: toInt(information?['total_sales']),
      averageRating: toDouble(information?['average_rating']),
      totalReviews: toInt(information?['total_reviews']),
      memberSince: information?['member_since']?.toString(),
      bio: information?['bio']?.toString(),
      bookingFees:
          toDouble(information?['booking_fees'] ?? json['booking_fees']),
      isLicensed: toBool(information?['is_licensed']),
      experienceYears: toInt(information?['experience_years']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'agent_id': agentId,
        'user_id': userId,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'area': area,
        'role': role,
        'latitude': latitude,
        'longitude': longitude,
        'login_status': loginStatus,
        'profile_picture_url': profilePictureUrl,
        'active_areas': activeAreas,
        'total_sales': totalSales,
        'average_rating': averageRating,
        'total_reviews': totalReviews,
        'member_since': memberSince,
        'bio': bio,
        'booking_fees': bookingFees,
        'is_licensed': isLicensed,
        'experience_years': experienceYears,
      };

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  String get profileImage =>
      (profilePictureUrl?.isNotEmpty == true) ? profilePictureUrl ?? '' : '';
}

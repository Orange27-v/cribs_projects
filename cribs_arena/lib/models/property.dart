import 'dart:convert';
import 'package:cribs_arena/models/agent.dart';

class Property {
  final int id;
  final String propertyId;
  final int? agentId;
  final String title;
  final String type;
  final String location;
  final String listingType;
  final double price;
  final int beds;
  final int baths;
  final int sqft;
  final String description;
  final String? address;
  final double inspectionFee;
  final String status;
  final double? latitude;
  final double? longitude;
  final List<String> images;
  final bool isFeatured;
  final bool isVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Agent? agent;
  final double? distanceKm; // Distance from user's location in kilometers
  final List<String> amenities;

  Property({
    required this.id,
    required this.propertyId,
    this.agentId,
    required this.title,
    required this.type,
    required this.location,
    required this.listingType,
    required this.price,
    required this.beds,
    required this.baths,
    required this.sqft,
    required this.description,
    this.address,
    required this.inspectionFee,
    required this.status,
    this.latitude,
    this.longitude,
    required this.images,
    required this.isFeatured,
    required this.isVerified,
    this.createdAt,
    this.updatedAt,
    this.agent,
    this.distanceKm,
    this.amenities = const [],
  });

  // Factory constructor with robust parsing
  factory Property.fromJson(Map<String, dynamic> json) {
    try {
      return Property(
        id: _JsonParser.parseInt(json['id'], fallback: 0),
        propertyId: _JsonParser.parseString(
          json['property_id'] ?? json['propertyId'] ?? json['id'],
        ),
        agentId:
            _JsonParser.parseIntOrNull(json['agent_id'] ?? json['agentId']),
        title: _JsonParser.parseString(json['title']),
        type: _JsonParser.parseString(json['type']),
        location: _JsonParser.parseString(json['location']),
        listingType: _JsonParser.parseString(
            json['listing_type'] ?? json['listingType']),
        price: _JsonParser.parseDouble(json['price'] ?? json['amount'],
            fallback: 0.0),
        beds: _JsonParser.parseInt(json['beds'], fallback: 0),
        baths: _JsonParser.parseInt(json['baths'], fallback: 0),
        sqft: _JsonParser.parseInt(json['sqft'], fallback: 0),
        description: _JsonParser.parseString(json['description']),
        address: _JsonParser.parseStringOrNull(json['address']),
        inspectionFee: _JsonParser.parseDouble(
            json['inspection_fee'] ?? json['inspectionFee'],
            fallback: 0.0),
        status: _JsonParser.parseString(json['status']),
        latitude:
            _JsonParser.parseDoubleOrNull(json['latitude'] ?? json['lat']),
        longitude:
            _JsonParser.parseDoubleOrNull(json['longitude'] ?? json['lon']),
        images: _JsonParser.parsePropertyImages(
          json['images'] ??
              json['image'] ??
              json['image_url'] ??
              json['images_json'],
        ),
        isFeatured:
            _JsonParser.parseBool(json['is_featured'] ?? json['isFeatured']),
        isVerified:
            _JsonParser.parseBool(json['is_verified'] ?? json['isVerified']),
        createdAt:
            _JsonParser.parseDateTime(json['created_at'] ?? json['createdAt']),
        updatedAt:
            _JsonParser.parseDateTime(json['updated_at'] ?? json['updatedAt']),
        agent: json['agent'] != null ? Agent.fromJson(json['agent']) : null,
        distanceKm: _JsonParser.parseDoubleOrNull(
            json['distance_km'] ?? json['distanceKm'] ?? json['distance']),
        amenities: _JsonParser.parseAmenities(json['amenities']),
      );
    } catch (e) {
      throw FormatException('Failed to parse Property from JSON: $e');
    }
  }

  // Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'property_id': propertyId,
        'agent_id': agentId,
        'title': title,
        'type': type,
        'location': location,
        'listing_type': listingType,
        'price': price,
        'beds': beds,
        'baths': baths,
        'sqft': sqft,
        'description': description,
        'address': address,
        'inspection_fee': inspectionFee,
        'status': status,
        'latitude': latitude,
        'longitude': longitude,
        'images': images,
        'is_featured': isFeatured,
        'is_verified': isVerified,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        if (agent != null) 'agent': agent!.toJson(),
        if (distanceKm != null) 'distance_km': distanceKm,
        'amenities': amenities,
      };

  // CopyWith method for immutability
  Property copyWith({
    int? id,
    String? propertyId,
    int? agentId,
    String? title,
    String? type,
    String? location,
    String? listingType,
    double? price,
    int? beds,
    int? baths,
    int? sqft,
    String? description,
    String? address,
    double? inspectionFee,
    String? status,
    double? latitude,
    double? longitude,
    List<String>? images,
    bool? isFeatured,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    Agent? agent,
    double? distanceKm,
    List<String>? amenities,
  }) {
    return Property(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      agentId: agentId ?? this.agentId,
      title: title ?? this.title,
      type: type ?? this.type,
      location: location ?? this.location,
      listingType: listingType ?? this.listingType,
      price: price ?? this.price,
      beds: beds ?? this.beds,
      baths: baths ?? this.baths,
      sqft: sqft ?? this.sqft,
      description: description ?? this.description,
      address: address ?? this.address,
      inspectionFee: inspectionFee ?? this.inspectionFee,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      images: images ?? this.images,
      isFeatured: isFeatured ?? this.isFeatured,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      agent: agent ?? this.agent,
      distanceKm: distanceKm ?? this.distanceKm,
      amenities: amenities ?? this.amenities,
    );
  }

  // Equality and hashCode
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Property &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          propertyId == other.propertyId;

  @override
  int get hashCode => id.hashCode ^ propertyId.hashCode;

  @override
  String toString() =>
      'Property(id: $id, propertyId: $propertyId, title: $title)';
}

// JSON Parsing Utilities
class _JsonParser {
  static int parseInt(dynamic value, {required int fallback}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static int? parseIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double parseDouble(dynamic value, {required double fallback}) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static double? parseDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static String? parseStringOrNull(dynamic value) {
    if (value == null) return null;
    final str = value.toString();
    return str.isEmpty ? null : str;
  }

  static bool parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }
    return false;
  }

  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static List<String> parsePropertyImages(dynamic value) {
    if (value == null) return [];

    List<String> images = [];

    if (value is List) {
      images = value
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (value is String) {
      try {
        final decoded = json.decode(value);
        if (decoded is List) {
          images = decoded
              .map((e) => e?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList();
        } else if (decoded is String) {
          images = [decoded];
        } else {
          images = [value];
        }
      } catch (_) {
        images = [value];
      }
    }

    return images
        .map((img) {
          if (img.startsWith('http')) {
            return img;
          } else {
            // If it's not a full URL, it's an unexpected relative path.
            // Return an empty string, which will be filtered out.
            return '';
          }
        })
        .where((s) => s.isNotEmpty)
        .toList(); // Filter out any empty strings (invalid paths)
  }

  static List<String> parseAmenities(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      try {
        final decoded = json.decode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (e) {
        // Fallback for simple string or manual parsing if needed
        // For now return empty or maybe split by comma if appropriate?
        // Let's assume JSON array string for now as per other implementations.
      }
    }
    return [];
  }
}

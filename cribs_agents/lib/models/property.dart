class Property {
  final int id;
  final String propertyId;
  final int agentId;
  final String title; // Changed from name
  final String type;
  final String location;
  final String listingType;
  final double price; // Changed from String
  final int beds;
  final int baths;
  final String? sqft;
  final String? description;
  final String? address;
  final double? inspectionFee;
  final String status;
  final double? latitude;
  final double? longitude;
  final List<String>? images; // Changed from imageUrl
  final bool isFeatured;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? amenities;
  final String? agentName; // New field for agent details
  final String? agentImageUrl; // New field for agent details
  final int viewCount;
  final int inspectionBookingCount;
  final int leadsCount;

  Property({
    required this.id,
    required this.propertyId,
    required this.agentId,
    required this.title,
    required this.type,
    required this.location,
    required this.listingType,
    required this.price,
    required this.beds,
    required this.baths,
    this.sqft,
    this.description,
    this.address,
    this.inspectionFee,
    required this.status,
    this.latitude,
    this.longitude,
    this.images,
    this.amenities,
    required this.isFeatured,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
    this.agentName,
    this.agentImageUrl,
    this.viewCount = 0,
    this.inspectionBookingCount = 0,
    this.leadsCount = 0,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: _parseInt(json['id']),
      propertyId: json['property_id']?.toString() ?? '',
      agentId: _parseInt(json['agent_id']),
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      listingType: json['listing_type']?.toString() ?? '',
      price: _parseDouble(json['price']),
      beds: _parseInt(json['beds']),
      baths: _parseInt(json['baths']),
      sqft: json['sqft']?.toString(),
      description: json['description']?.toString(),
      address: json['address']?.toString(),
      inspectionFee: _parseDoubleNullable(json['inspection_fee']),
      status: json['status']?.toString() ?? 'Pending',
      latitude: _parseDoubleNullable(json['latitude']),
      longitude: _parseDoubleNullable(json['longitude']),
      images: json['images'] != null
          ? (json['images'] as List).map((e) => e.toString()).toList()
          : null,
      amenities: _parseAmenities(json['amenities']),
      isFeatured: _parseBool(json['is_featured']),
      isVerified: _parseBool(json['is_verified']),
      createdAt:
          DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now(),
      agentName: json['agent'] != null &&
              json['agent']['first_name'] != null &&
              json['agent']['last_name'] != null
          ? '${json['agent']['first_name']} ${json['agent']['last_name']}'
          : null,
      agentImageUrl: json['agent']?['profile_picture_url']?.toString(),
      viewCount: _parseInt(json['view_count']),
      inspectionBookingCount: _parseInt(json['inspection_booking_count']),
      leadsCount: _parseInt(json['leads_count']),
    );
  }

  static List<String>? _parseAmenities(dynamic value) {
    if (value == null) return null;
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) {
      try {
        // Handle JSON string case if backend sends it as string
        if (value.startsWith('[')) {
          // You might need dart:convert if not already imported, but let's assume
          // simple string manipulation or that the caller handles decoding.
          // Since we can't easily add imports here without replacing whole file,
          // we'll rely on the standard regex or assuming it comes as List from backend
          // if casted correctly. But wait, if backend doesn't cast, it is a String.
          // We need dart:convert. PropertyService usually handles decoding the RESPONSE body.
          // But individual fields inside might still be JSON strings.
          // Let's use specific regex to extract if we don't want to rely on jsonDecode being available.
          // actually, imports are at top of file. 'dart:convert' is likely not there?
          // I checked the file, no 'dart:convert' import seen in prev view_file.
          // I will use a simple regex approach which is safer without imports.
          final RegExp regExp = RegExp(r'"([^"]*)"');
          return regExp.allMatches(value).map((m) => m.group(1)!).toList();
        }
      } catch (e) {
        return null; // fallback
      }
    }
    return null;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      if (value.toLowerCase() == 'null') return 0;
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      if (value.toLowerCase() == 'null') return 0.0;
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static double? _parseDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      if (value.isEmpty || value.toLowerCase() == 'null') return null;
      return double.tryParse(value);
    }
    return null;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }
}

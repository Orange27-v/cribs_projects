import 'dart:async';
import 'package:cribs_arena/models/property.dart';
import 'package:cribs_arena/services/property_service.dart';
import 'package:cribs_arena/services/recommended_property_service.dart'; // Import the new service
import 'package:cribs_arena/exceptions/network_exception.dart'; // Add this import
import 'package:flutter/foundation.dart';

/// Service for generating quick search tags based on properties
class QuickSearchService {
  final PropertyService _propertyService;
  final RecommendedPropertyService
      _recommendedPropertyService; // New service instance

  // Default fallback tags for common Lagos locations
  static const List<String> _defaultTags = [
    '3 Bedroom flat, Lekki',
    'Commercial Space, Lekki',
    'Victoria Island',
    '2 Bedroom, Yaba',
    'Duplex, Ikoyi',
    'Studio, Surulere',
    'Office Space, Victoria Island',
    'Apartment, Ajah',
    'House, Ikeja',
    'Shop, Maryland',
  ];

  QuickSearchService(
      {PropertyService? propertyService,
      RecommendedPropertyService? recommendedPropertyService})
      : _propertyService = propertyService ?? PropertyService(),
        _recommendedPropertyService = recommendedPropertyService ??
            RecommendedPropertyService(); // Initialize new service

  /// Returns user-friendly quick search tags.
  ///
  /// If [latitude] and [longitude] are provided, derives tags from nearby
  /// recommended properties. Otherwise, returns static fallback tags.
  ///
  /// [max] limits the number of tags returned (default: 10)
  Future<List<String>> getTags({
    double? latitude,
    double? longitude,
    int max = 10,
  }) async {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', 'Must be greater than 0');
    }

    try {
      final properties = await getTagProperties(
        latitude: latitude,
        longitude: longitude,
        max: max,
      );

      if (properties.isNotEmpty) {
        final labels = _generateLabelsFromProperties(properties);
        if (labels.isNotEmpty) {
          return labels.take(max).toList();
        }
      }
    } on NetworkException catch (e) {
      // Log network errors but continue to fallback
      _logError('Network error getting tags: ${e.message}');
    } catch (e) {
      // Log unexpected errors
      _logError('Unexpected error getting tags: $e');
    }

    // Return fallback tags
    return _defaultTags.take(max).toList();
  }

  /// Returns a list of [Property] items for quick-search tags.
  ///
  /// Attempts to fetch recommended properties based on location,
  /// falls back to general properties if unavailable.
  ///
  /// Returns a deduplicated list limited to [max] items.
  Future<List<Property>> getTagProperties({
    double? latitude,
    double? longitude,
    int max = 10,
  }) async {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', 'Must be greater than 0');
    }

    List<Property> properties = [];

    try {
      // Try location-based recommendations first using RecommendedPropertyService
      if (latitude != null && longitude != null) {
        properties = await _recommendedPropertyService.getRecommendedProperties(
          latitude,
          longitude,
        );
      }

      // Fallback to general properties if no recommendations
      if (properties.isEmpty) {
        final response = await _propertyService.getAllProperties(page: 1);
        properties = response.data;
      }
    } on NetworkException catch (e) {
      _logError('Network error fetching properties: ${e.message}');
      return [];
    } catch (e) {
      _logError('Error fetching properties: $e');
      return [];
    }

    // Return deduplicated properties
    return _deduplicateProperties(properties, max);
  }

  /// Removes duplicate properties based on propertyId
  List<Property> _deduplicateProperties(List<Property> properties, int max) {
    final seen = <String>{};
    final unique = <Property>[];

    for (final property in properties) {
      final id = property.propertyId;

      // Skip if already seen
      if (seen.contains(id)) continue;

      seen.add(id);
      unique.add(property);

      // Stop when we reach the limit
      if (unique.length >= max) break;
    }

    return unique;
  }

  /// Generates human-readable labels from properties
  List<String> _generateLabelsFromProperties(List<Property> properties) {
    final labels = <String>[];

    for (final property in properties) {
      final label = _createPropertyLabel(property);
      if (label != null && label.isNotEmpty) {
        labels.add(label);
      }
    }

    return labels;
  }

  /// Creates a single label from a property
  ///
  /// Priority order:
  /// 1. "{beds} Bedroom {type}, {location}"
  /// 2. "{title}, {location}"
  /// 3. "{type}, {location}"
  /// 4. "{location}"
  String? _createPropertyLabel(Property property) {
    final location = property.location.trim();

    // No location means no useful label
    if (location.isEmpty) return null;

    // Best case: beds + type + location
    if (property.beds > 0 && property.type.isNotEmpty) {
      final bedroomText = property.beds == 1 ? 'Bedroom' : 'Bedrooms';
      return '${property.beds} $bedroomText ${property.type}, $location';
    }

    // Good case: title + location
    if (property.title.isNotEmpty) {
      return '${property.title.trim()}, $location';
    }

    // Acceptable case: type + location
    if (property.type.isNotEmpty) {
      return '${property.type.trim()}, $location';
    }

    // Fallback: just location
    return location;
  }

  /// Simple error logger (replace with your logging implementation)
  void _logError(String message) {
    // TODO: Integrate with your app's logging system
    // For now, just print to console in debug mode
    // ignore: avoid_print
    assert(() {
      debugPrint('[QuickSearchService] $message');
      return true;
    }());
  }

  /// Dispose resources
  void dispose() {
    _propertyService.dispose();
    _recommendedPropertyService.dispose(); // Dispose the new service
  }
}

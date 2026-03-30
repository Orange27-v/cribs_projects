import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/models/property.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'token_storage_service.dart';

/// Service for managing property operations
class PropertyService {
  final String baseUrl = kBaseUrl;
  final TokenStorageService _tokenStorage = TokenStorageService();

  /// Add a new property
  Future<Map<String, dynamic>> addProperty({
    required String title,
    required String type,
    required String location,
    required String listingType,
    required double price,
    required int beds,
    required int baths,
    String? sqft,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    List<File>? propertyImages,
    List<String>? amenities,
  }) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      final uri = Uri.parse('$baseUrl/agent/properties/add');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add fields
      request.fields['title'] = title;
      request.fields['type'] = type;
      request.fields['location'] = location;
      request.fields['listing_type'] = listingType;
      request.fields['price'] = price.toString();
      request.fields['beds'] = beds.toString();
      request.fields['baths'] = baths.toString();

      if (sqft != null && sqft.isNotEmpty) {
        request.fields['sqft'] = sqft;
      }

      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }
      if (address != null && address.isNotEmpty) {
        request.fields['address'] = address;
      }
      if (latitude != null) {
        request.fields['latitude'] = latitude.toString();
      }
      if (longitude != null) {
        request.fields['longitude'] = longitude.toString();
      }

      // Add amenities as a JSON array if provided
      if (amenities != null && amenities.isNotEmpty) {
        request.fields['amenities'] = jsonEncode(amenities);
      }

      // Add property images if provided
      if (propertyImages != null && propertyImages.isNotEmpty) {
        for (int i = 0; i < propertyImages.length; i++) {
          final file = propertyImages[i];
          final mimeType = lookupMimeType(file.path);
          final multipartFile = await http.MultipartFile.fromPath(
            'images[]',
            file.path,
            contentType: mimeType != null
                ? MediaType.parse(mimeType)
                : MediaType('image', 'jpeg'),
          );
          request.files.add(multipartFile);
        }
      }

      debugPrint('Adding new property...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Property added successfully',
          'data': responseData['property'],
        };
      } else if (response.statusCode == 401) {
        await _tokenStorage.clearToken();
        return {
          'success': false,
          'message': 'Session expired. Please log in again.',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              errorData['message']?.toString() ?? 'Failed to add property',
          'errors': errorData['errors'],
        };
      }
    } catch (e) {
      debugPrint('Error adding property: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Get all properties for the authenticated agent
  Future<Map<String, dynamic>> getAgentProperties({
    int page = 1,
    int perPage = 20,
    String? status,
    String? listingType,
  }) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      // Build query parameters
      final queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (status != null) queryParams['status'] = status;
      if (listingType != null) queryParams['listing_type'] = listingType;

      final uri = Uri.parse('$baseUrl/agent/properties').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint(
          'Get agent properties response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<Property> properties = [];

        if (responseData['properties'] != null &&
            responseData['properties']['data'] != null) {
          for (var propertyJson in responseData['properties']['data']) {
            try {
              properties.add(Property.fromJson(propertyJson));
            } catch (e) {
              debugPrint('Error parsing property: $e');
              debugPrint('Property JSON: $propertyJson');
            }
          }
        }

        return {
          'success': true,
          'properties': properties,
          'pagination':
              responseData['properties']['meta'] ?? responseData['properties'],
        };
      } else if (response.statusCode == 401) {
        await _tokenStorage.clearToken();
        return {
          'success': false,
          'message': 'Session expired. Please log in again.',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              errorData['message']?.toString() ?? 'Failed to fetch properties',
        };
      }
    } catch (e) {
      debugPrint('Error fetching agent properties: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Get a single property by ID
  Future<Map<String, dynamic>> getProperty(String propertyId) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/agent/properties/$propertyId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Get property response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'property': Property.fromJson(responseData['property']),
        };
      } else if (response.statusCode == 401) {
        await _tokenStorage.clearToken();
        return {
          'success': false,
          'message': 'Session expired. Please log in again.',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Property not found',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch property',
        };
      }
    } catch (e) {
      debugPrint('Error fetching property: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Update an existing property
  Future<Map<String, dynamic>> updateProperty({
    required String propertyId,
    String? title,
    String? type,
    String? location,
    String? listingType,
    double? price,
    int? beds,
    int? baths,
    String? sqft,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    String? status,
    List<File>? newImages,
    List<String>? imagesToDelete,
    List<String>? amenities,
  }) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      final uri = Uri.parse('$baseUrl/agent/properties/$propertyId/update');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add _method field for Laravel to recognize this as a PUT request
      // request.fields['_method'] = 'PUT'; // Removed because route is defined as POST

      // Add fields only if they are provided
      if (title != null) request.fields['title'] = title;
      if (type != null) request.fields['type'] = type;
      if (location != null) request.fields['location'] = location;
      if (listingType != null) request.fields['listing_type'] = listingType;
      if (price != null) request.fields['price'] = price.toString();
      if (beds != null) request.fields['beds'] = beds.toString();
      if (baths != null) request.fields['baths'] = baths.toString();
      if (sqft != null) request.fields['sqft'] = sqft;
      if (description != null) request.fields['description'] = description;
      if (address != null) request.fields['address'] = address;
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();
      if (status != null) request.fields['status'] = status;

      // Add amenities if provided
      if (amenities != null) {
        request.fields['amenities'] = jsonEncode(amenities);
      }

      // Add images to delete if provided
      if (imagesToDelete != null && imagesToDelete.isNotEmpty) {
        request.fields['delete_images'] = jsonEncode(imagesToDelete);
      }

      // Add new images if provided
      if (newImages != null && newImages.isNotEmpty) {
        for (int i = 0; i < newImages.length; i++) {
          final file = newImages[i];
          final mimeType = lookupMimeType(file.path);
          final multipartFile = await http.MultipartFile.fromPath(
            'images[]',
            file.path,
            contentType: mimeType != null
                ? MediaType.parse(mimeType)
                : MediaType('image', 'jpeg'),
          );
          request.files.add(multipartFile);
        }
      }

      debugPrint('Updating property $propertyId...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Property updated successfully',
          'data': responseData['property'],
        };
      } else if (response.statusCode == 401) {
        await _tokenStorage.clearToken();
        return {
          'success': false,
          'message': 'Session expired. Please log in again.',
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'You do not have permission to update this property',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Property not found',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              errorData['message']?.toString() ?? 'Failed to update property',
          'errors': errorData['errors'],
        };
      }
    } catch (e) {
      debugPrint('Error updating property: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Delete a property
  Future<Map<String, dynamic>> deleteProperty(String propertyId) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      final uri = Uri.parse('$baseUrl/agent/properties/$propertyId');
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Delete property response status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Property deleted successfully',
        };
      } else if (response.statusCode == 401) {
        await _tokenStorage.clearToken();
        return {
          'success': false,
          'message': 'Session expired. Please log in again.',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to delete property',
        };
      }
    } catch (e) {
      debugPrint('Error deleting property: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }
}

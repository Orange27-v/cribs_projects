import 'package:cribs_agents/models/property.dart';

class ListedProperty {
  final String id;
  final String title;
  final String location;
  final String type;
  final String imageUrl;
  final int beds;
  final int baths;
  final String? sqft;
  final double? price;
  final bool isBookmarked;

  const ListedProperty({
    required this.id,
    required this.title,
    required this.location,
    required this.type,
    required this.imageUrl,
    required this.beds,
    required this.baths,
    this.sqft,
    this.price,
    this.isBookmarked = false,
  });

  ListedProperty copyWith({
    String? id,
    String? title,
    String? location,
    String? type,
    String? imageUrl,
    int? beds,
    int? baths,
    String? sqft,
    double? price,
    bool? isBookmarked,
  }) {
    return ListedProperty(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      beds: beds ?? this.beds,
      baths: baths ?? this.baths,
      sqft: sqft ?? this.sqft,
      price: price ?? this.price,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'type': type,
      'imageUrl': imageUrl,
      'beds': beds,
      'baths': baths,
      'sqft': sqft,
      'price': price,
      'isBookmarked': isBookmarked,
    };
  }

  factory ListedProperty.fromJson(Map<String, dynamic> json) {
    return ListedProperty(
      id: json['id'] as String,
      title: json['title'] as String,
      location: json['location'] as String,
      type: json['type'] as String,
      imageUrl: json['imageUrl'] as String,
      beds: json['beds'] as int,
      baths: json['baths'] as int,
      sqft: json['sqft'] as String?,
      price: json['price']?.toDouble(),
      isBookmarked: json['isBookmarked'] as bool? ?? false,
    );
  }

  factory ListedProperty.fromProperty(Property property) {
    return ListedProperty(
      id: property.id.toString(), // Convert int id to String
      title: property.title,
      location: property.location,
      type: property.type,
      imageUrl: property.images != null && property.images!.isNotEmpty
          ? property.images![0] // Use the first image if available
          : 'assets/images/property1.jpg', // Placeholder if no images
      beds: property.beds,
      baths: property.baths,
      sqft: property.sqft,
      price: property.price,
      isBookmarked:
          false, // Default to false, as bookmarking is user-specific and not in Property model
    );
  }

  @override
  String toString() {
    return 'ListedProperty(id: $id, title: $title, location: $location, type: $type, beds: $beds, baths: $baths)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ListedProperty && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

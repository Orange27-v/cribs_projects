import 'package:cribs_arena/models/property.dart';

class ListedProperty {
  final String id;
  final String title;
  final String location;
  final String type;
  final List<String> images;
  final int beds;
  final int baths;
  final int? sqft;
  final double? price;
  final bool isBookmarked;

  const ListedProperty({
    required this.id,
    required this.title,
    required this.location,
    required this.type,
    required this.images,
    required this.beds,
    required this.baths,
    this.sqft,
    this.price,
    this.isBookmarked = false,
  });

  factory ListedProperty.fromProperty(Property property,
      {bool isBookmarked = false}) {
    return ListedProperty(
      id: property.propertyId,
      title: property.title,
      location: property.location,
      type: property.type,
      images: property.images.isNotEmpty
          ? property.images
          : ['assets/images/property_skeleton.jpg'], // Consistent placeholder
      beds: property.beds,
      baths: property.baths,
      sqft: property.sqft,
      price: property.price,
      isBookmarked: isBookmarked,
    );
  }

  ListedProperty copyWith({
    String? id,
    String? title,
    String? location,
    String? type,
    List<String>? images,
    int? beds,
    int? baths,
    int? sqft,
    double? price,
    bool? isBookmarked,
  }) {
    return ListedProperty(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      type: type ?? this.type,
      images: images ?? this.images,
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
      'images': images,
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
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      beds: json['beds'] as int,
      baths: json['baths'] as int,
      sqft: json['sqft'] != null
          ? int.tryParse(json['sqft'].toString()) ?? 0
          : null,
      price: json['price']?.toDouble(),
      isBookmarked: json['isBookmarked'] as bool? ?? false,
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

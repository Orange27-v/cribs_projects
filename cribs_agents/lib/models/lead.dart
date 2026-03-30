class Lead {
  final int id;
  final int userId;
  final int propertyId;
  final LeadUser? user;
  final LeadProperty? property;

  Lead({
    required this.id,
    required this.userId,
    required this.propertyId,
    this.user,
    this.property,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id'],
      userId: json['user_id'],
      propertyId: json['property_id'],
      user: json['user'] != null ? LeadUser.fromJson(json['user']) : null,
      property: json['property'] != null
          ? LeadProperty.fromJson(json['property'])
          : null,
    );
  }
}

class LeadUser {
  final int id;
  final int userId; // The 6-digit user ID
  final String firstName;
  final String lastName;
  final String? profilePictureUrl;
  final String? phone;

  LeadUser({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.profilePictureUrl,
    this.phone,
  });

  String get fullName => '$firstName $lastName';

  factory LeadUser.fromJson(Map<String, dynamic> json) {
    return LeadUser(
      id: json['id'],
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse(json['user_id'].toString()) ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      profilePictureUrl: json['profile_picture_url'],
      phone: json['phone'],
    );
  }
}

class LeadProperty {
  final int id;
  final String title;
  final String address;
  final String price;
  final String? mainImageUrl;

  LeadProperty({
    required this.id,
    required this.title,
    required this.address,
    required this.price,
    this.mainImageUrl,
  });

  factory LeadProperty.fromJson(Map<String, dynamic> json) {
    return LeadProperty(
      id: json['id'],
      title: json['title'] ?? 'Unknown Property',
      address: json['address'] ?? '',
      price: json['price']?.toString() ?? '0',
      mainImageUrl: json['main_image_url'],
    );
  }
}

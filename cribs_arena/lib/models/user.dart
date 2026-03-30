class User {
  final String id;
  final String? firstName;
  final String? lastName;
  final String email;
  final String? phone;
  final String? area;
  final String? profilePictureUrl;

  User({
    required this.id,
    this.firstName,
    this.lastName,
    required this.email,
    this.phone,
    this.area,
    this.profilePictureUrl,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id']?.toString() ?? json['id']?.toString() ?? '',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      area: json['area'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'area': area,
      'profile_picture_url': profilePictureUrl,
    };
  }
}

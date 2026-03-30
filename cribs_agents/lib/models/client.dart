class Client {
  final int id;
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? profilePictureUrl;
  final String? area;
  final DateTime? createdAt;
  final String? inspectionStatus;
  final String? inspectionDate;

  Client({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.profilePictureUrl,
    this.area,
    this.createdAt,
    this.inspectionStatus,
    this.inspectionDate,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      userId: json['user_id'] is int
          ? json['user_id']
          : int.parse(json['user_id'].toString()),
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profilePictureUrl: json['profile_picture_url'],
      area: json['area'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      inspectionStatus: json['inspection_status'],
      inspectionDate: json['inspection_date'],
    );
  }

  String get fullName => '$firstName $lastName';
}

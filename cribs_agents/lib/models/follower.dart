/// Model for a follower (user who saved this agent)
class Follower {
  final int id;
  final int userId;
  final String? createdAt;
  final FollowerUser? user;

  Follower({
    required this.id,
    required this.userId,
    this.createdAt,
    this.user,
  });

  factory Follower.fromJson(Map<String, dynamic> json) {
    return Follower(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      createdAt: json['created_at'],
      user: json['user'] != null ? FollowerUser.fromJson(json['user']) : null,
    );
  }
}

class FollowerUser {
  final int id;
  final int userId;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? profilePictureUrl;

  FollowerUser({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.profilePictureUrl,
  });

  String get fullName => '$firstName $lastName';

  factory FollowerUser.fromJson(Map<String, dynamic> json) {
    return FollowerUser(
      id: json['id'] ?? 0,
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse(json['user_id'].toString()) ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      profilePictureUrl: json['profile_picture_url'],
    );
  }
}

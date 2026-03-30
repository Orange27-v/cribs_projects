class Review {
  final int id;
  final int rating;
  final String reviewText;
  final String userName;
  final String userPhotoUrl;
  final String createdAt;

  Review({
    required this.id,
    required this.rating,
    required this.reviewText,
    required this.userName,
    required this.userPhotoUrl,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      rating: json['rating'] is int
          ? json['rating']
          : int.tryParse(json['rating'].toString()) ?? 0,
      reviewText: json['review_text'],
      userName: json['user'] != null
          ? "${json['user']['first_name']} ${json['user']['last_name']}"
          : 'Anonymous',
      userPhotoUrl:
          json['user'] != null ? json['user']['profile_picture_url'] : '',
      createdAt: json['created_at'],
    );
  }
}

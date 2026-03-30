import 'dart:convert';

class NotificationModel {
  final String id;
  final String receiverId;
  final String receiverType;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.receiverId,
    required this.receiverType,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    dynamic jsonData = json['data'];
    Map<String, dynamic> dataMap = {};
    if (jsonData is String) {
      if (jsonData.isNotEmpty) {
        try {
          dataMap = jsonDecode(jsonData);
        } catch (e) {
          // Not a valid JSON string, leave as empty map
        }
      }
    } else if (jsonData is Map<String, dynamic>) {
      dataMap = jsonData;
    }

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      receiverId: json['receiver_id']?.toString() ?? '',
      receiverType: json['receiver_type']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      data: dataMap,
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receiver_id': receiverId,
      'receiver_type': receiverType,
      'type': type,
      'title': title,
      'body': body,
      'data': jsonEncode(data),
      'is_read': isRead ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

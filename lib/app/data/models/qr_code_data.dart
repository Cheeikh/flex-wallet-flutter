import 'dart:convert';

class QRCodeData {
  final String userId;
  final String phone;
  final String name;
  final DateTime timestamp;

  QRCodeData({
    required this.userId,
    required this.phone,
    required this.name,
    required this.timestamp,
  });

  String toJson() {
    return jsonEncode({
      'userId': userId,
      'phone': phone,
      'name': name,
      'timestamp': timestamp.toIso8601String(),
    });
  }

  factory QRCodeData.fromJson(String jsonString) {
    final Map<String, dynamic> data = jsonDecode(jsonString);
    
    return QRCodeData(
      userId: data['userId'] ?? '',
      phone: data['phone'] ?? '',
      name: data['name'] ?? '',
      timestamp: DateTime.parse(data['timestamp']),
    );
  }
} 
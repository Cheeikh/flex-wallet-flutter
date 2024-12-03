import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? name;
  final String? phone;
  final String? email;
  final double balance;
  final double? transactionLimit;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.uid,
    this.name,
    this.phone,
    this.email,
    this.balance = 0.0,
    this.transactionLimit,
    this.profileImageUrl,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      name: data['name'],
      phone: data['phone'],
      email: data['email'],
      balance: (data['balance'] ?? 0.0).toDouble(),
      transactionLimit: data['transactionLimit']?.toDouble(),
      profileImageUrl: data['profileImageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'balance': balance,
      'transactionLimit': transactionLimit,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? email,
    double? balance,
    double? transactionLimit,
    String? profileImageUrl,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      balance: balance ?? this.balance,
      transactionLimit: transactionLimit ?? this.transactionLimit,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
} 
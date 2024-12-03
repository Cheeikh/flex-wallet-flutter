import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class DistributorModel extends UserModel {
  final double maxBalance;
  final List<String> allowedOperations;

  DistributorModel({
    required String uid,
    required String name,
    required String phone,
    required DateTime createdAt,
    double balance = 0.0,
    this.maxBalance = 1000000.0,
    this.allowedOperations = const ['deposit', 'withdrawal'],
  }) : super(
          uid: uid,
          name: name,
          phone: phone,
          createdAt: createdAt,
          balance: balance,
        );

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'maxBalance': maxBalance,
      'allowedOperations': allowedOperations,
    });
    return map;
  }

  factory DistributorModel.fromMap(Map<String, dynamic> map) {
    return DistributorModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      balance: (map['balance'] ?? 0.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      maxBalance: (map['maxBalance'] ?? 1000000.0).toDouble(),
      allowedOperations: List<String>.from(map['allowedOperations'] ?? []),
    );
  }
} 
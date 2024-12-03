import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'user_role.dart';

class AppUser {
  final String uid;
  final String? email;
  final String? phone;
  final String? name;
  final UserRole role;
  final double balance;

  AppUser({
    required this.uid,
    this.email,
    this.phone,
    this.name,
    required this.role,
    this.balance = 0.0,
  });

  factory AppUser.fromFirebaseUser(
    firebase_auth.User user, {
    UserRole role = UserRole.client,
    String? name,
    String? phone,
    double balance = 0.0,
  }) {
    return AppUser(
      uid: user.uid,
      email: user.email,
      phone: phone ?? user.phoneNumber,
      name: name ?? user.displayName,
      role: role,
      balance: balance,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'phone': phone,
      'name': name,
      'role': role.toString(),
      'balance': balance,
    };
  }
} 
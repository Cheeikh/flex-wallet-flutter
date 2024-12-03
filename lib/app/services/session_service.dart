import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modules/auth/controllers/auth_controller.dart';

class SessionService extends GetxService {
  final _firestore = FirebaseFirestore.instance;
  Timer? _activityTimer;
  
  void startActivityTracking() {
    _activityTimer?.cancel();
    _activityTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      updateLastActivity();
    });
  }

  Future<void> updateLastActivity() async {
    final userId = Get.find<AuthController>().currentUser?.uid;
    if (userId != null) {
      await _firestore.collection('users').doc(userId).update({
        'lastActivity': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  void onClose() {
    _activityTimer?.cancel();
    super.onClose();
  }
} 
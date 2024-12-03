import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/user_model.dart';

class UserService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache pour éviter de trop nombreuses requêtes
  final Map<String, UserModel> _userCache = {};

  Future<UserModel?> getUser(String userId) async {
    // Vérifier d'abord le cache
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final user = UserModel.fromFirestore(doc);
      // Mettre en cache
      _userCache[userId] = user;
      return user;
    } catch (e) {
      return null;
    }
  }

  // Vider le cache si nécessaire
  void clearCache() {
    _userCache.clear();
  }
} 
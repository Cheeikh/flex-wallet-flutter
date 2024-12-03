import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static Future<void> init() async {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBtcrTWkcMIt-OpztSESRIMWHZayBmnXcs",
          authDomain: "flex-wallet.firebaseapp.com",
          projectId: "flex-wallet",
          storageBucket: "flex-wallet.firebasestorage.app",
          messagingSenderId: "213180313712",
          appId: "1:213180313712:web:a393ccaed308cbd63b44b5"
        ),
      );
      
      // Configuration de Firestore
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      
      // Configuration de l'authentification
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      
    } catch (e) {
      print('Erreur d\'initialisation Firebase: $e');
      rethrow;
    }
  }
} 
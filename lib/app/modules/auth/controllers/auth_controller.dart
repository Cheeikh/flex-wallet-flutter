import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../../../routes/app_pages.dart';
import '../views/phone_completion_view.dart';
import 'package:firebase_auth/firebase_auth.dart' show GoogleAuthProvider;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthController extends GetxController {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Rx<AppUser?> _currentUser = Rx<AppUser?>(null);
  
  // Form controllers
  late final GlobalKey<FormState> loginFormKey;
  late final GlobalKey<FormState> registerFormKey;
  late final GlobalKey<FormState> phoneFormKey;
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  
  // Loading state
  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  
  AppUser? get currentUser => _currentUser.value;

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  Map<String, dynamic>? _tempGoogleUserData;
  
  // Ajouter une propriété pour stocker temporairement les données Facebook
  Map<String, dynamic>? _tempFacebookUserData;
  
  @override
  void onInit() {
    loginFormKey = GlobalKey<FormState>(debugLabel: 'loginForm');
    registerFormKey = GlobalKey<FormState>(debugLabel: 'registerForm');
    phoneFormKey = GlobalKey<FormState>(debugLabel: 'phoneForm');
    
    _currentUser.bindStream(_auth.authStateChanges().asyncMap((user) async {
      if (user != null) {
        // Récupérer les données utilisateur depuis Firestore
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          // S'assurer que le solde est bien converti en double
          final balance = (data['balance'] is int) 
              ? (data['balance'] as int).toDouble() 
              : (data['balance'] ?? 0.0).toDouble();
          
          print('Solde récupéré: $balance'); // Debug

          return AppUser.fromFirebaseUser(
            user,
            role: UserRole.values.firstWhere(
              (r) => r.toString() == data['role'],
              orElse: () => UserRole.client,
            ),
            balance: balance,
            name: data['name'],
            phone: data['phone'],
          );
        }
      }
      return null;
    }));
    super.onInit();
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  String formatPhoneNumber(String phone) {
    // Nettoyer le numéro
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Ajouter +221 si nécessaire
    if (!cleaned.startsWith('+')) {
      if (cleaned.startsWith('221')) {
        cleaned = '+$cleaned';
      } else {
        cleaned = '+221$cleaned';
      }
    }
    return cleaned;
  }

  String phoneToEmail(String phone) {
    return "${formatPhoneNumber(phone).replaceAll('+', '')}@domain.com";
  }

  String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'Veuillez entrer votre numéro';
    }
    
    String formatted = formatPhoneNumber(phone);
    final phoneRegex = RegExp(r'^\+221[0-9]{9}$');
    
    if (!phoneRegex.hasMatch(formatted)) {
      return 'Format invalide. Exemple: +221776543210';
    }
    return null;
  }



  Future<void> login({required String phone, required String password}) async {
    try {
      if (!loginFormKey.currentState!.validate()) return;
      
      isLoading.value = true;
      final formattedPhone = formatPhoneNumber(phone);
      
      // Vérifier d'abord si l'utilisateur existe dans Firestore
      final userQuery = await _firestore
          .collection('users')
          .where('phone', isEqualTo: formattedPhone)
          .get();

      if (userQuery.docs.isEmpty) {
        throw firebase_auth.FirebaseAuthException(
          code: 'user-not-found',
          message: 'Aucun compte trouvé avec ce numéro',
        );
      }

      final email = phoneToEmail(formattedPhone);
      print('Tentative de connexion avec: $email');

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw firebase_auth.FirebaseAuthException(
            code: 'timeout',
            message: 'Délai de connexion dépassé',
          );
        },
      );

      if (userCredential.user != null) {
        final doc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
            
        if (!doc.exists) {
          throw firebase_auth.FirebaseAuthException(
            code: 'user-not-found',
            message: 'Données utilisateur introuvables',
          );
        }

        final data = doc.data()!;
        if (data['active'] == false) {
          throw firebase_auth.FirebaseAuthException(
            code: 'user-disabled',
            message: 'Ce compte a été désactivé',
          );
        }

        // Mettre à jour les données de session avec une meilleure gestion des plateformes
        final sessionData = {
          'lastLogin': FieldValue.serverTimestamp(),
          'isOnline': true,
          'lastActivity': FieldValue.serverTimestamp(),
          'deviceInfo': _getDeviceInfo(),
        };

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .update(sessionData);

        _currentUser.value = AppUser.fromFirebaseUser(
          userCredential.user!,
          role: UserRole.values.firstWhere(
            (r) => r.toString() == data['role'],
            orElse: () => UserRole.client,
          ),
          name: data['name'],
          phone: formattedPhone,
          balance: (data['balance'] ?? 0.0).toDouble(),
        );

        print('Connexion réussie: ${_currentUser.value?.toMap()}');

        Get.offAllNamed(
          _currentUser.value!.role == UserRole.client
              ? Routes.clientDashboard
              : Routes.distributorDashboard,
        );
      }
    } catch (e) {
      print('Erreur de connexion: $e');
      String message = 'Une erreur est survenue';
      
      if (e is firebase_auth.FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            message = 'Aucun compte trouvé avec ce numéro';
            break;
          case 'wrong-password':
            message = 'Mot de passe incorrect';
            break;
          case 'user-disabled':
            message = 'Ce compte a été désactivé';
            break;
          case 'timeout':
            message = 'Délai de connexion dépassé';
            break;
          default:
            message = 'Erreur de connexion: ${e.message}';
        }
      }
      
      Get.snackbar(
        'Erreur',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register({
    required String name,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    try {
      if (!registerFormKey.currentState!.validate()) return;
      
      isLoading.value = true;
      final formattedPhone = formatPhoneNumber(phone);
      
      // Définir les limites par défaut selon le rôle
      const defaultClientLimit = 500000.0;  // 500,000 FCFA pour les clients
      const defaultDistributorLimit = 10000000.0;  // 10,000,000 FCFA pour les distributeurs
      
      // Utiliser une transaction Firestore
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Vérifier si le numéro existe déjà
        final userQuery = await _firestore
            .collection('users')
            .where('phone', isEqualTo: formattedPhone)
            .get();

        if (userQuery.docs.isNotEmpty) {
          throw firebase_auth.FirebaseAuthException(
            code: 'phone-already-in-use',
            message: 'Ce numéro est déjà utilisé',
          );
        }

        // Créer l'utilisateur dans Firebase Auth
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: phoneToEmail(phone),
          password: password,
        );

        if (userCredential.user == null) {
          throw Exception('Échec de création du compte');
        }

        // Définir la limite en fonction du rôle
        final limit = role == UserRole.client ? defaultClientLimit : defaultDistributorLimit;

        // Créer le document utilisateur dans Firestore avec les limites
        final userRef = _firestore.collection('users').doc(userCredential.user!.uid);
        transaction.set(userRef, {
          'name': name,
          'phone': formattedPhone,
          'role': role.toString(),
          'balance': 0.0,
          'maxTransactionLimit': limit,  // Plafond restant
          'initialTransactionLimit': limit,  // Plafond initial
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'active': true,
        });

        return userCredential;
      });

      // Mettre à jour l'état de l'utilisateur
      final user = _auth.currentUser;
      if (user != null) {
        _currentUser.value = AppUser.fromFirebaseUser(
          user,
          role: role,
          name: name,
        );
        
        Get.offAllNamed(
          role == UserRole.client
              ? Routes.clientDashboard
              : Routes.distributorDashboard,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Échec de l\'inscription: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      // Mettre à jour lastLogout dans Firestore
      final userId = _currentUser.value?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'lastLogout': FieldValue.serverTimestamp(),
          'isOnline': false,
        });
      }

      // Effacer les données locales
      _currentUser.value = null;
      
      // Nettoyer les contrôleurs non permanents
      Get.deleteAll(force: false); // Ne supprime pas les contrôleurs permanents
      
      // Réinitialiser les contrôleurs de formulaire
      nameController.clear();
      phoneController.clear();
      passwordController.clear();
      
      // Déconnexion Firebase
      await _auth.signOut();
      
      // Redirection
      Get.offAllNamed(Routes.login);
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Échec de la déconnexion: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Méthode pour la connexion Google
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // D'abord connecter l'utilisateur avec Google
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Vérifier si l'utilisateur existe déjà dans Firestore
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();

      if (userDoc.exists) {
        // L'utilisateur existe déjà, le connecter directement
        print('Utilisateur Google existant trouvé');
        Get.offAllNamed(Routes.clientDashboard);
      } else {
        // Nouvel utilisateur, stocker les données temporairement et demander le numéro
        _tempGoogleUserData = {
          'name': googleUser.displayName,
          'email': googleUser.email,
          'photoUrl': googleUser.photoUrl,
          'credential': credential,
        };

        // Rediriger vers la vue de complétion du numéro de téléphone
        Get.to(() => PhoneCompletionView(
              name: googleUser.displayName,
              email: googleUser.email,
              photoUrl: googleUser.photoUrl,
            ));
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Échec de la connexion avec Google: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> completeGoogleSignIn({required String phone}) async {
    if (_tempGoogleUserData == null) {
      Get.snackbar('Erreur', 'Données de connexion Google non trouvées');
      return;
    }

    if (!phoneFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      // Connecter l'utilisateur avec les credentials Google
      final userCredential = await _auth.signInWithCredential(
          _tempGoogleUserData!['credential']);

      const defaultClientLimit = 500000.0;  // Limite par défaut pour les clients

      // Créer l'utilisateur dans Firestore avec le numéro de téléphone et les limites
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': _tempGoogleUserData!['name'],
        'email': _tempGoogleUserData!['email'],
        'phone': phone,
        'role': UserRole.client.toString(),
        'balance': 0.0,
        'maxTransactionLimit': defaultClientLimit,  // Plafond restant
        'initialTransactionLimit': defaultClientLimit,  // Plafond initial
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'active': true,
      });

      // Nettoyer les données temporaires
      _tempGoogleUserData = null;

      // Rediriger vers la page d'accueil
      Get.offAllNamed(Routes.clientDashboard);
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Échec de la finalisation de l\'inscription: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode pour la connexion Facebook
  Future<void> signInWithFacebook() async {
    try {
      isLoading.value = true;

      // Déconnexion préalable pour éviter les problèmes de token
      await FacebookAuth.instance.logOut();
      
      // Initialiser la connexion Facebook avec les permissions requises
      final LoginResult loginResult = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
        loginBehavior: LoginBehavior.nativeWithFallback, // Ajouter ceci
      );

      if (loginResult.status == LoginStatus.success) {
        final AccessToken accessToken = loginResult.accessToken!;
        
        // Vérifier que le token est valide
        if (accessToken.token.isEmpty) {
          throw Exception('Token Facebook invalide');
        }

        // Obtenir les informations du profil Facebook
        final userData = await FacebookAuth.instance.getUserData(
          fields: "name,email,picture.width(200)",
        );

        print('Données Facebook reçues: $userData'); // Debug

        // Créer les credentials Firebase
        final credential = firebase_auth.FacebookAuthProvider.credential(
          accessToken.token,
        );

        try {
          // Connecter avec Firebase
          final userCredential = await _auth.signInWithCredential(credential);
          
          // Vérifier si l'utilisateur existe déjà dans Firestore
          final userDoc = await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

          if (userDoc.exists) {
            // Mettre à jour la dernière connexion
            await _firestore.collection('users').doc(userCredential.user!.uid).update({
              'lastLogin': FieldValue.serverTimestamp(),
              'isOnline': true,
            });
            
            Get.offAllNamed(Routes.clientDashboard);
          } else {
            // Stocker les données pour la complétion du profil
            _tempFacebookUserData = {
              'name': userData['name'],
              'email': userData['email'],
              'photoUrl': userData['picture']?['data']?['url'],
              'credential': credential,
              'uid': userCredential.user!.uid,
            };

            Get.to(() => PhoneCompletionView(
                  name: userData['name'],
                  email: userData['email'],
                  photoUrl: userData['picture']?['data']?['url'],
                  isFacebookLogin: true,
                ));
          }
        } on firebase_auth.FirebaseAuthException catch (e) {
          print('Erreur Firebase: $e'); // Debug
          handleFirebaseAuthError(e);
        }
      } else {
        print('Statut de connexion Facebook: ${loginResult.status}'); // Debug
        throw Exception('Échec de la connexion Facebook: ${loginResult.message}');
      }
    } catch (e) {
      print('Erreur Facebook détaillée: $e'); // Debug
      Get.snackbar(
        'Erreur',
        'Échec de connexion avec Facebook: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Ajouter cette méthode helper
  void handleFirebaseAuthError(firebase_auth.FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'account-exists-with-different-credential':
        message = 'Ce compte existe déjà avec une autre méthode de connexion';
        break;
      case 'invalid-credential':
        message = 'Les informations de connexion sont invalides';
        break;
      default:
        message = 'Erreur de connexion: ${e.message}';
    }
    Get.snackbar('Erreur', message, snackPosition: SnackPosition.BOTTOM);
  }

  // Ajouter une nouvelle méthode pour compléter l'inscription Facebook
  Future<void> completeFacebookSignIn({required String phone}) async {
    if (_tempFacebookUserData == null) {
      Get.snackbar('Erreur', 'Données de connexion Facebook non trouvées');
      return;
    }

    if (!phoneFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      final formattedPhone = formatPhoneNumber(phone);

      // Vérifier si le numéro de téléphone existe déjà
      final phoneQuery = await _firestore
          .collection('users')
          .where('phone', isEqualTo: formattedPhone)
          .get();

      if (phoneQuery.docs.isNotEmpty) {
        Get.snackbar(
          'Erreur',
          'Ce numéro de téléphone est déjà utilisé',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      const defaultClientLimit = 500000.0;  // Limite par défaut pour les clients

      // Sauvegarder l'utilisateur dans Firestore avec les limites
      await _firestore.collection('users').doc(_tempFacebookUserData!['uid']).set({
        'name': _tempFacebookUserData!['name'],
        'email': _tempFacebookUserData!['email'],
        'phone': formattedPhone,
        'role': UserRole.client.toString(),
        'balance': 0.0,
        'maxTransactionLimit': defaultClientLimit,  // Plafond restant
        'initialTransactionLimit': defaultClientLimit,  // Plafond initial
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isOnline': true,
        'active': true,
        'photoUrl': _tempFacebookUserData!['photoUrl'],
      });

      // Nettoyer les données temporaires
      _tempFacebookUserData = null;

      // Rediriger vers la page d'accueil
      Get.offAllNamed(Routes.clientDashboard);
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Échec de la finalisation de l\'inscription: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Ajouter cette méthode helper pour obtenir les informations du dispositif
  Map<String, dynamic> _getDeviceInfo() {
    if (kIsWeb) {
      return {
        'platform': 'web',
        'userAgent': 'web browser', // Valeur par défaut pour le web
      };
    } else {
      return {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
      };
    }
  }

  // Méthode pour basculer la visibilité du mot de passe
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
} 
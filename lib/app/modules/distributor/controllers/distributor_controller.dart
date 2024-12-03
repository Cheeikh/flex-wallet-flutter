import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/transaction_model.dart';
import '../../auth/controllers/auth_controller.dart';
import 'package:uuid/uuid.dart';

class DistributorController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController authController = Get.find<AuthController>();
  final RxDouble balance = 0.0.obs;
  final RxBool isBalanceVisible = true.obs;
  final RxBool isLoading = false.obs;
  final RxString selectedFilter = 'all'.obs;
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final uuid = const Uuid();
  StreamSubscription<QuerySnapshot>? _transactionsSubscription;

  // Garder une copie de toutes les transactions pour le filtrage
  final _allTransactions = <TransactionModel>[].obs;
  List<TransactionModel> get allTransactions => _allTransactions;
  
  // Rafraîchir les données
  Future<void> refreshData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        fetchBalance(),
        fetchTransactions(),
      ]);
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de rafraîchir les données',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Filtrer les transactions
  void filterTransactions(String filter) {
    selectedFilter.value = filter;
    // Implémenter la logique de filtrage selon le filtre sélectionné
    switch (filter) {
      case 'today':
        final today = DateTime.now();
        transactions.value = allTransactions.where((t) => 
          t.createdAt.year == today.year &&
          t.createdAt.month == today.month &&
          t.createdAt.day == today.day
        ).toList();
        break;
      case 'week':
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        transactions.value = allTransactions.where((t) => 
          t.createdAt.isAfter(weekAgo)
        ).toList();
        break;
      case 'month':
        final monthAgo = DateTime.now().subtract(const Duration(days: 30));
        transactions.value = allTransactions.where((t) => 
          t.createdAt.isAfter(monthAgo)
        ).toList();
        break;
      case 'all':
      default:
        transactions.value = List.from(allTransactions);
    }
  }

  @override
  void onInit() {
    super.onInit();
    refreshData();
  }

  void _setupTransactionsListener() {
    final currentUser = Get.find<AuthController>().currentUser;
    if (currentUser == null) return;

    _transactionsSubscription = _firestore
        .collection('transactions')
        .where('fromUserId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      transactions.value = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  void onClose() {
    _transactionsSubscription?.cancel();
    super.onClose();
  }

  Future<void> deposit({
    required String userPhone,
    required double amount,
    String? description,
  }) async {
    isLoading.value = true;
    try {
      final distributorId = authController.currentUser?.uid;
      if (distributorId == null) {
        throw Exception('Distributeur non connecté');
      }

      // Vérifier le client
      final clientQuery = await _firestore
          .collection('users')
          .where('phone', isEqualTo: authController.formatPhoneNumber(userPhone))
          .get();

      if (clientQuery.docs.isEmpty) {
        throw Exception('Client non trouvé');
      }

      final clientId = clientQuery.docs.first.id;
      final now = DateTime.now();

      // Créer la transaction dans Firestore
      await _firestore.runTransaction((transaction) async {
        // Vérifier le solde du distributeur
        final distributorDoc = await transaction.get(
          _firestore.collection('users').doc(distributorId)
        );
        
        final currentBalance = (distributorDoc.data()?['balance'] ?? 0.0).toDouble();
        
        if (currentBalance < amount) {
          throw Exception('Solde insuffisant');
        }

        // Mettre à jour les soldes
        transaction.update(
          _firestore.collection('users').doc(distributorId),
          {'balance': FieldValue.increment(-amount)}
        );
        
        transaction.update(
          _firestore.collection('users').doc(clientId),
          {'balance': FieldValue.increment(amount)}
        );

        // Créer l'enregistrement de transaction
        final transactionRef = _firestore.collection('transactions').doc();
        transaction.set(transactionRef, {
          'id': transactionRef.id,
          'fromUserId': distributorId,
          'toUserId': clientId,
          'amount': amount,
          'description': description,
          'type': 'deposit',
          'createdAt': Timestamp.fromDate(now),
          'isCancelable': false, // Les dépôts ne sont pas annulables
        });
      });

      // Recharger le solde et les transactions
      await fetchBalance();
      await fetchTransactions();
      
      Get.snackbar(
        'Succès',
        'Dépôt effectué avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Erreur lors du dépôt: $e');
      Get.snackbar(
        'Erreur',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> withdraw({
    required String userPhone,
    required double amount,
    String? description,
  }) async {
    isLoading.value = true;
    try {
      final distributorId = authController.currentUser?.uid;
      if (distributorId == null) {
        throw Exception('Distributeur non connecté');
      }

      // Vérifier le client
      final clientQuery = await _firestore
          .collection('users')
          .where('phone', isEqualTo: authController.formatPhoneNumber(userPhone))
          .get();

      if (clientQuery.docs.isEmpty) {
        throw Exception('Client non trouvé');
      }

      final clientId = clientQuery.docs.first.id;
      final now = DateTime.now();

      // Créer la transaction dans Firestore
      await _firestore.runTransaction((transaction) async {
        // Vérifier le solde du client
        final clientDoc = await transaction.get(
          _firestore.collection('users').doc(clientId)
        );
        
        final clientBalance = (clientDoc.data()?['balance'] ?? 0.0).toDouble();
        
        if (clientBalance < amount) {
          throw Exception('Solde client insuffisant');
        }

        // Mettre à jour les soldes
        transaction.update(
          _firestore.collection('users').doc(clientId),
          {'balance': FieldValue.increment(-amount)}
        );
        
        transaction.update(
          _firestore.collection('users').doc(distributorId),
          {'balance': FieldValue.increment(amount)}
        );

        // Créer l'enregistrement de transaction
        final transactionRef = _firestore.collection('transactions').doc();
        transaction.set(transactionRef, {
          'id': transactionRef.id,
          'fromUserId': clientId,  // Le client est l'expéditeur dans un retrait
          'toUserId': distributorId,  // Le distributeur est le destinataire
          'amount': amount,
          'description': description,
          'type': 'withdrawal',
          'createdAt': Timestamp.fromDate(now),
          'isCancelable': false,  // Les retraits ne sont pas annulables
        });
      });

      // Recharger le solde et les transactions
      await fetchBalance();
      await fetchTransactions();
      
      Get.snackbar(
        'Succès',
        'Retrait effectué avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Erreur lors du retrait: $e');
      Get.snackbar(
        'Erreur',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadTransactions() async {
    try {
      final currentUser = Get.find<AuthController>().currentUser;
      if (currentUser == null) return;

      final snapshot = await _firestore
          .collection('transactions')
          .where('fromUserId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .get();

      transactions.value = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les transactions');
    }
  }

  Future<void> updateUserLimit({
    required String userPhone,
    required double newLimit,
  }) async {
    isLoading.value = true;
    try {
      final userDoc = await _firestore
          .collection('users')
          .where('phone', isEqualTo: userPhone)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) {
        throw Exception('Utilisateur non trouvé');
      }

      final userId = userDoc.docs.first.id;
      await _firestore.collection('users').doc(userId).update({
        'maxTransactionLimit': newLimit,
      });

      Get.snackbar('Succès', 'Limite mise à jour avec succès');
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchBalance() async {
    try {
      final currentUser = Get.find<AuthController>().currentUser;
      if (currentUser == null) return;

      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        final rawBalance = doc.data()?['balance'];
        balance.value = (rawBalance is int) 
            ? rawBalance.toDouble() 
            : (rawBalance ?? 0.0).toDouble();
      }
    } catch (e) {
      print('Erreur lors du chargement du solde: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger le solde',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> fetchTransactions() async {
    try {
      await loadTransactions(); // Utilise la méthode existante loadTransactions()
    } catch (e) {
      print('Erreur lors du chargement des transactions: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger les transactions',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Méthode pour basculer la visibilité du solde
  void toggleBalanceVisibility() {
    isBalanceVisible.value = !isBalanceVisible.value;
  }
} 
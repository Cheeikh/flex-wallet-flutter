import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/recurring_transfer_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/qr_code_data.dart';
import '../../../providers/transfer_provider.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ClientController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final authController = Get.find<AuthController>();
  final unreadNotifications = 0.obs;
  
  final balance = 0.0.obs;
  final isBalanceVisible = true.obs;
  final transactions = <TransactionModel>[].obs;
  final selectedFilter = 'all'.obs;
  final RxList<RecurringTransferModel> recurringTransfers = <RecurringTransferModel>[].obs;
  final notifications = <NotificationModel>[].obs;
  StreamSubscription<QuerySnapshot>? _notificationsSubscription;
  final balanceVariation = 0.0.obs;
  final isLoading = false.obs;
  StreamSubscription<QuerySnapshot>? _recurringTransfersSubscription;
  final Rx<QRCodeData?> transferRecipient = Rx<QRCodeData?>(null);

  final registeredContacts = <Contact>[].obs;
  final allContacts = <Contact>[].obs;
  final isLoadingContacts = false.obs;

  final showAllContacts = false.obs;
  final searchQuery = ''.obs;

  final _transferProvider = Get.find<TransferProvider>();

  // Rafraîchir les données
  Future<void> refreshData() async {
    isLoading.value = true;
    try {
      final oldBalance = balance.value;
      // Récupérer le nouveau solde
      await fetchBalance();
      // Calculer la variation
      balanceVariation.value = balance.value - oldBalance;
      
      // Récupérer les autres données
      await fetchTransactions();
      await fetchNotifications();
      await _loadRecurringTransfers();
    } catch (e) {
      print('Erreur lors du rafraîchissement des données: $e');
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

  // Garder une copie de toutes les transactions pour le filtrage
  final _allTransactions = <TransactionModel>[].obs;
  List<TransactionModel> get allTransactions => _allTransactions;
  
  @override
  void onInit() {
    super.onInit();
    _setupRecurringTransfersListener();
    refreshData();
  }

  void toggleBalanceVisibility() {
    isBalanceVisible.value = !isBalanceVisible.value;
  }

  Future<void> loadBalance() async {
    try {
      final userId = authController.currentUser?.uid;
      if (userId == null) return;

      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final rawBalance = doc.data()?['balance'];
        final newBalance = (rawBalance is int) 
            ? rawBalance.toDouble() 
            : (rawBalance ?? 0.0).toDouble();
            
        print('Solde chargé: $newBalance'); // Debug
        balance.value = newBalance;
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

  Future<void> transfer({
    required String toPhone,
    required double amount,
    String? description,
  }) async {
    try {
      final fromUserId = authController.currentUser?.uid;
      if (fromUserId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Vérifier le destinataire
      final recipientQuery = await _firestore
          .collection('users')
          .where('phone', isEqualTo: authController.formatPhoneNumber(toPhone))
          .get();

      if (recipientQuery.docs.isEmpty) {
        throw Exception('Destinataire non trouvé');
      }

      final toUserId = recipientQuery.docs.first.id;
      final now = DateTime.now(); // Capture l'heure exacte
      
      // Créer la transaction dans Firestore
      await _firestore.runTransaction((transaction) async {
        // Vérifier le solde de l'expéditeur
        final senderDoc = await transaction.get(
          _firestore.collection('users').doc(fromUserId)
        );
        
        final currentBalance = (senderDoc.data()?['balance'] ?? 0.0).toDouble();
        
        if (currentBalance < amount) {
          throw Exception('Solde insuffisant');
        }

        // Mettre à jour les soldes
        transaction.update(
          _firestore.collection('users').doc(fromUserId),
          {'balance': FieldValue.increment(-amount)}
        );
        
        transaction.update(
          _firestore.collection('users').doc(toUserId),
          {'balance': FieldValue.increment(amount)}
        );

        // Créer l'enregistrement de transaction
        final transactionRef = _firestore.collection('transactions').doc();
        transaction.set(transactionRef, {
          'id': transactionRef.id,
          'fromUserId': fromUserId,
          'toUserId': toUserId,
          'amount': amount,
          'description': description,
          'type': 'transfer',
          'createdAt': Timestamp.fromDate(now), // Utilise l'heure capturée
          'isCancelable': true,
          'cancelableUntil': Timestamp.fromDate(
            now.add(const Duration(minutes: 30)) // Utilise l'heure capturée + 30 minutes
          ),
        });
      });

      // Recharger le solde et les transactions
      await loadBalance();
      await loadTransactions();
      
      Get.snackbar(
        'Succès',
        'Transfert effectué avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> loadTransactions() async {
    try {
      final userId = authController.currentUser?.uid;
      if (userId == null) return;

      // Charger les transactions envoyées et reçues
      final query = await _firestore
          .collection('transactions')
          .where(
            Filter.or(
              Filter('fromUserId', isEqualTo: userId),
              Filter('toUserId', isEqualTo: userId),
            ),
          )
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final allTransactions = query.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();

      transactions.value = allTransactions;
      _allTransactions.value = allTransactions;
    } catch (e) {
      print('Erreur lors du chargement des transactions: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger les transactions',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> multiTransfer({
    required List<String> phones,
    required double amount,
    String? description,
  }) async {
    try {
      for (final phone in phones) {
        await transfer(
          toPhone: phone,
          amount: amount,
          description: description,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> createRecurringTransfer({
    required String toPhone,
    required double amount,
    required RecurringFrequency frequency,
    required DateTime startDate,
    required TimeOfDay executionTime,
    DateTime? endDate,
    String? description,
  }) async {
    try {
      final currentUser = Get.find<AuthController>().currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      final transferId = const Uuid().v4();
      final now = DateTime.now();
      
      final transfer = RecurringTransferModel(
        id: transferId,
        fromUserId: currentUser.uid,
        toPhone: toPhone,
        amount: amount,
        frequency: frequency,
        startDate: startDate,
        executionTime: executionTime,
        endDate: endDate,
        description: description,
        createdAt: now,
      );

      await _firestore
          .collection('recurring_transfers')
          .doc(transferId)
          .set(transfer.toMap());

      Get.snackbar(
        'Succès',
        'Transfert récurrent créé',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Erreur lors de la création du transfert récurrent: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de créer le transfert récurrent',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      rethrow;
    }
  }

  Future<void> cancelRecurringTransfer(String transferId) async {
    try {
      await _firestore.collection('recurring_transfers').doc(transferId).update({
        'isActive': false
      });
      recurringTransfers.removeWhere((transfer) => transfer.id == transferId);
      
      Get.snackbar('Succès', 'Transfert récurrent annulé');
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible d\'annuler le transfert récurrent');
    }
  }

  Future<void> _loadRecurringTransfers() async {
    try {
      final userId = authController.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await _firestore
          .collection('recurring_transfers')
          .where('fromUserId', isEqualTo: userId)
          
          .get();

      recurringTransfers.value = snapshot.docs
          .map((doc) => RecurringTransferModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les transferts récurrents');
    }
  }

  Future<void> fetchBalance() async {
    try {
      // Récupérer le solde depuis Firestore
      final doc = await _firestore
          .collection('users')
          .doc(authController.currentUser?.uid)
          .get();
      
      if (doc.exists) {
        balance.value = (doc.data()?['balance'] ?? 0.0).toDouble();
      }
    } catch (e) {
      print('Erreur lors de la récupération du solde: $e');
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

  Future<void> fetchNotifications() async {
    try {
      final userId = authController.currentUser?.uid;
      if (userId == null) return;

      // Annuler l'ancienne souscription si elle existe
      await _notificationsSubscription?.cancel();

      // Créer une nouvelle souscription
      _notificationsSubscription = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(50) // Limiter le nombre de notifications
          .snapshots()
          .listen(
        (snapshot) {
          unreadNotifications.value = snapshot.docs.length;
          notifications.value = snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();
        },
        onError: (error) {
          print('Erreur lors de l\'écoute des notifications: $error');
          if (error.toString().contains('requires an index')) {
            Get.snackbar(
              'Information',
              'Configuration des notifications en cours...',
              duration: const Duration(seconds: 5),
            );
          }
        },
      );
    } catch (e) {
      print('Erreur lors du chargement des notifications: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger les notifications',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> loadData() async {
    try {
      // Implémentez ici la logique de rechargement des données
      await Future.delayed(const Duration(seconds: 1)); // Simulation
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les données: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Erreur lors du marquage de la notification: $e');
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      final batch = _firestore.batch();
      final unreadNotificationsDocs = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: authController.currentUser?.uid)
          .where('read', isEqualTo: false)
          .get();

      for (var doc in unreadNotificationsDocs.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
      unreadNotifications.value = 0;
    } catch (e) {
      print('Erreur lors du marquage des notifications: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de marquer les notifications comme lues',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> cancelTransaction(String transactionId) async {
    try {
      isLoading.value = true;
      
      final doc = await _firestore
          .collection('transactions')
          .doc(transactionId)
          .get();
      
      if (!doc.exists) {
        throw 'Transaction introuvable';
      }
      
      final transactionData = TransactionModel.fromFirestore(doc);
      
      if (!transactionData.canBeCanceled) {
        throw 'Cette transaction ne peut plus être annulée';
      }

      await _firestore.runTransaction((transaction) async {
        // Mettre à jour la transaction
        await _firestore
            .collection('transactions')
            .doc(transactionId)
            .update({
          'status': TransactionStatus.canceled.toString().split('.').last,
          'canceledAt': FieldValue.serverTimestamp(),
          'canceledBy': authController.currentUser?.uid,
        });

        // Rembourser l'expéditeur et débiter le destinataire
        await _firestore
            .collection('users')
            .doc(transactionData.fromUserId)
            .update({
          'balance': FieldValue.increment(transactionData.amount),
        });

        await _firestore
            .collection('users')
            .doc(transactionData.toUserId)
            .update({
          'balance': FieldValue.increment(-transactionData.amount),
        });
      });

      await refreshData();
      
      Get.snackbar(
        'Succès',
        'Transaction annulée avec succès',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _recurringTransfersSubscription?.cancel();
    _notificationsSubscription?.cancel();
    super.onClose();
  }

  void _setupRecurringTransfersListener() {
    final currentUser = Get.find<AuthController>().currentUser;
    if (currentUser == null) {
      print('Aucun utilisateur connecté');
      return;
    }

    print('Configuration du listener pour l\'utilisateur: ${currentUser.uid}');

    // Annuler l'ancien listener s'il existe
    _recurringTransfersSubscription?.cancel();

    _recurringTransfersSubscription = _firestore
        .collection('recurring_transfers')
        .where('fromUserId', isEqualTo: currentUser.uid)
        .snapshots()
        .listen(
      (snapshot) {
        print('Réception de ${snapshot.docs.length} transferts récurrents');
        
        // Trier les transferts après les avoir récupérés
        final transfers = snapshot.docs
            .map((doc) => RecurringTransferModel.fromFirestore(doc))
            .toList();
            
        transfers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        recurringTransfers.value = transfers;
        print('Liste mise à jour avec ${recurringTransfers.length} transferts');
      },
      onError: (error) {
        print('Erreur du listener: $error');
      },
    );
  }

  Future<void> toggleRecurringTransfer(String transferId) async {
    try {
      // Trouver le transfert dans la liste locale
      final index = recurringTransfers.indexWhere((t) => t.id == transferId);
      if (index == -1) {
        throw Exception('Transfert non trouvé');
      }

      // Créer une nouvelle instance avec l'état inversé
      final oldTransfer = recurringTransfers[index];
      final newTransfer = RecurringTransferModel(
        id: oldTransfer.id,
        fromUserId: oldTransfer.fromUserId,
        toPhone: oldTransfer.toPhone,
        amount: oldTransfer.amount,
        frequency: oldTransfer.frequency,
        startDate: oldTransfer.startDate,
        executionTime: oldTransfer.executionTime,
        endDate: oldTransfer.endDate,
        description: oldTransfer.description,
        lastExecuted: oldTransfer.lastExecuted,
        isActive: !oldTransfer.isActive,
        createdAt: oldTransfer.createdAt,
      );

      // Mettre à jour la liste locale immédiatement
      final newList = List<RecurringTransferModel>.from(recurringTransfers);
      newList[index] = newTransfer;
      recurringTransfers.value = newList;

      // Mettre à jour Firestore
      await _firestore
          .collection('recurring_transfers')
          .doc(transferId)
          .update({
        'isActive': newTransfer.isActive,
      });

      Get.snackbar(
        'Succès',
        newTransfer.isActive 
            ? 'Transfert récurrent activé'
            : 'Transfert récurrent désactivé',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Erreur lors de la modification du transfert récurrent: $e');
      // En cas d'erreur, restaurer l'état précédent
      _setupRecurringTransfersListener();
      Get.snackbar(
        'Erreur',
        'Impossible de modifier le transfert récurrent',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> deleteRecurringTransfer(String transferId) async {
    try {
      await _firestore
          .collection('recurring_transfers')
          .doc(transferId)
          .delete();

      Get.snackbar(
        'Succès',
        'Transfert récurrent supprimé',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Erreur lors de la suppression du transfert récurrent: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer le transfert récurrent',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void setTransferRecipient(QRCodeData data) {
    transferRecipient.value = data;
  }

  void clearTransferRecipient() {
    transferRecipient.value = null;
  }

  Future<void> loadRegisteredContacts() async {
    try {
      isLoadingContacts.value = true;
      
      // Charger tous les contacts du téléphone
      if (await FlutterContacts.requestPermission()) {
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: true,
        );
        allContacts.value = contacts;

        // Récupérer les numéros enregistrés depuis Firestore
        final registeredNumbers = await _firestore
            .collection('users')
            .get()
            .then((snapshot) => snapshot.docs
                .map((doc) => doc.data()['phone'] as String?)
                .where((phone) => phone != null)
                .toList());

        // Filtrer les contacts qui ont un compte
        registeredContacts.value = contacts.where((contact) {
          return contact.phones.any((phone) {
            final formattedNumber = _formatPhoneNumber(phone.number);
            return registeredNumbers.contains(formattedNumber);
          });
        }).toList();
      }
    } catch (e) {
      print('Erreur lors du chargement des contacts: $e');
    } finally {
      isLoadingContacts.value = false;
    }
  }

  String _formatPhoneNumber(String phone) {
    // Même logique de formatage que précédemment
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith('+')) {
      if (cleaned.startsWith('221')) {
        cleaned = '+$cleaned';
      } else if (cleaned.startsWith('00221')) {
        cleaned = '+${cleaned.substring(2)}';
      } else if (cleaned.length == 9) {
        cleaned = '+221$cleaned';
      }
    }
    return cleaned;
  }

  Future<void> retryFailedTransfer(String transactionId, String originalToUserId) async {
    try {
      await _transferProvider.retryFailedTransfer(transactionId, originalToUserId);
      
      // Rafraîchir les données après la relance
      await refreshData();
      
      Get.snackbar(
        'Succès',
        'Le transfert a été relancé avec succès',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de relancer le transfert: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
} 
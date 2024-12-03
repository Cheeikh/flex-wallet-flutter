import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../data/models/transaction_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class RealtimeNotificationService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  StreamSubscription<QuerySnapshot>? _transactionSubscription;
  String? _currentUserId;

  @override
  void onInit() {
    super.onInit();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _notifications.initialize(initializationSettings);
  }

  void startListening(String userId) {
    _currentUserId = userId;
    _transactionSubscription?.cancel();
    _transactionSubscription = _firestore
        .collection('transactions')
        .where('toUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(_handleTransactionUpdate);
  }

  void _handleTransactionUpdate(QuerySnapshot snapshot) {
    if (_currentUserId == null) return;

    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        final transaction = TransactionModel.fromMap(
          change.doc.data() as Map<String, dynamic>,
        );
        
        if (transaction.toUserId == _currentUserId && 
            DateTime.now().difference(transaction.createdAt).inMinutes < 1) {
          _showNotification(transaction);
        }
      }
    }
  }

  Future<void> _showNotification(TransactionModel transaction) async {
    final fromUserDoc = await _firestore.collection('users').doc(transaction.fromUserId).get();
    final fromUserName = fromUserDoc.data()?['name'] ?? 'Utilisateur';

    String title;
    String body;

    switch (transaction.type) {
      case TransactionType.deposit:
        title = 'Nouveau dépôt reçu';
        body = 'Dépôt de ${transaction.amount} FCFA de $fromUserName';
        break;
      case TransactionType.withdrawal:
        title = 'Retrait effectué';
        body = 'Retrait de ${transaction.amount} FCFA par $fromUserName';
        break;
      case TransactionType.transfer:
        title = 'Transfert reçu';
        body = 'Transfert de ${transaction.amount} FCFA de $fromUserName';
        break;
      case TransactionType.canceledTransfer:
        title = 'Transfert annulé';
        body = 'Le transfert de ${transaction.amount} FCFA de $fromUserName a été annulé';
        break;
      case TransactionType.recurringTransfer:
        title = 'Transfert programmé exécuté';
        body = 'Le transfert programmé de ${transaction.amount} FCFA de $fromUserName a été effectué';
        break;
    }

    const androidDetails = AndroidNotificationDetails(
      'transactions_channel',
      'Transactions',
      channelDescription: 'Notifications des transactions',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      transaction.hashCode,
      title,
      body,
      details,
    );
  }

  @override
  void onClose() {
    _transactionSubscription?.cancel();
    super.onClose();
  }
} 
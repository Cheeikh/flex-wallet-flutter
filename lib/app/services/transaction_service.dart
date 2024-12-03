import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/error_handler.dart';
import '../core/utils/app_error.dart';
import '../data/models/transaction_model.dart';

class TransactionService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> executeTransaction({
    required String fromUserId,
    required String toUserId,
    required double amount,
    required TransactionType type,
    String? description,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Vérifier les soldes et limites
        final fromUserDoc = await transaction.get(
          _firestore.collection('users').doc(fromUserId)
        );
        final toUserDoc = await transaction.get(
          _firestore.collection('users').doc(toUserId)
        );

        if (!fromUserDoc.exists || !toUserDoc.exists) {
          throw AppError(message: 'Utilisateur non trouvé');
        }

        final fromUserData = fromUserDoc.data()!;
        final fromUserBalance = fromUserData['balance'] ?? 0.0;
        final maxTransactionLimit = (fromUserData['maxTransactionLimit'] ?? 0.0).toDouble();

        // Vérifier le solde
        if (fromUserBalance < amount) {
          throw AppError(message: 'Solde insuffisant');
        }

        // Vérifier le plafond
        if (maxTransactionLimit <= 0) {
          throw AppError(
            message: 'Vous avez atteint votre plafond de transactions. Veuillez contacter un distributeur pour le déplafonner.'
          );
        }

        // Vérifier si le montant dépasse la limite restante
        if (amount > maxTransactionLimit) {
          throw AppError(
            message: 'Le montant dépasse votre plafond restant de ${maxTransactionLimit.toStringAsFixed(0)} FCFA'
          );
        }

        // Calculer la nouvelle limite
        final newLimit = maxTransactionLimit - amount;

        // Exécuter la transaction
        transaction.update(
          fromUserDoc.reference,
          {
            'balance': FieldValue.increment(-amount),
            'maxTransactionLimit': newLimit,
          }
        );
        
        transaction.update(
          toUserDoc.reference,
          {'balance': FieldValue.increment(amount)}
        );

        // Enregistrer l'historique
        transaction.set(
          _firestore.collection('transactions').doc(),
          {
            'fromUserId': fromUserId,
            'toUserId': toUserId,
            'amount': amount,
            'type': type.name,
            'description': description,
            'createdAt': FieldValue.serverTimestamp(),
            'remainingLimit': newLimit,
          }
        );

        // Si la nouvelle limite est à zéro, créer une notification
        if (newLimit <= 0) {
          transaction.set(
            _firestore.collection('notifications').doc(),
            {
              'userId': fromUserId,
              'title': 'Plafond atteint',
              'message': 'Vous avez atteint votre plafond de transactions. Contactez un distributeur pour le déplafonner.',
              'type': 'limit_reached',
              'createdAt': FieldValue.serverTimestamp(),
              'read': false,
            }
          );
        }
        // Si la limite est basse (moins de 20% du plafond initial), créer une alerte
        else if (newLimit < (fromUserData['initialTransactionLimit'] ?? 500000) * 0.2) {
          transaction.set(
            _firestore.collection('notifications').doc(),
            {
              'userId': fromUserId,
              'title': 'Plafond bientôt atteint',
              'message': 'Il vous reste ${newLimit.toStringAsFixed(0)} FCFA de plafond de transactions.',
              'type': 'limit_warning',
              'createdAt': FieldValue.serverTimestamp(),
              'read': false,
            }
          );
        }
      });
    } catch (e) {
      throw ErrorHandler.handleFirebaseError(e);
    }
  }

  Future<void> retryFailedTransaction({
    required String transactionId,
    required String toUserId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Vérifier que l'ID de transaction n'est pas vide
        if (transactionId.isEmpty) {
          throw AppError(message: 'ID de transaction invalide');
        }

        final transactionDoc = await transaction.get(
          _firestore.collection('transactions').doc(transactionId)
        );
        
        if (!transactionDoc.exists) {
          throw AppError(message: 'Transaction non trouvée');
        }
        
        final failedTransaction = TransactionModel.fromFirestore(transactionDoc);
        
        // Vérifier que c'est bien une transaction échouée
        if (failedTransaction.status != TransactionStatus.failed) {
          throw AppError(message: 'Cette transaction ne peut pas être relancée');
        }

        // Créer un nouvel ID pour la nouvelle transaction
        final newTransactionRef = _firestore.collection('transactions').doc();
        
        // Exécuter le transfert
        transaction.update(
          _firestore.collection('users').doc(failedTransaction.fromUserId),
          {'balance': FieldValue.increment(-failedTransaction.amount)}
        );
        
        transaction.update(
          _firestore.collection('users').doc(toUserId),
          {'balance': FieldValue.increment(failedTransaction.amount)}
        );

        // Créer une nouvelle transaction
        transaction.set(newTransactionRef, {
          'id': newTransactionRef.id,
          'fromUserId': failedTransaction.fromUserId,
          'toUserId': toUserId,
          'amount': failedTransaction.amount,
          'type': failedTransaction.type.toString().split('.').last,
          'description': failedTransaction.description,
          'createdAt': FieldValue.serverTimestamp(),
          'status': TransactionStatus.success.toString().split('.').last,
        });
        
        // Mettre à jour le statut de la transaction originale
        transaction.update(
          transactionDoc.reference,
          {
            'status': TransactionStatus.retrying.toString().split('.').last,
            'retryCount': FieldValue.increment(1),
            'lastRetryAt': FieldValue.serverTimestamp(),
            'retryTransactionId': newTransactionRef.id,
          }
        );
      });
    } catch (e) {
      throw ErrorHandler.handleFirebaseError(e);
    }
  }
} 
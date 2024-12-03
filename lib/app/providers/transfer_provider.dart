import 'package:get/get.dart';
import '../data/models/transaction_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/error_handler.dart';
import '../core/utils/app_error.dart';

class TransferProvider extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> retryFailedTransfer(String transactionId, String toUserId) async {
    try {
      if (transactionId.isEmpty) {
        throw AppError(message: 'ID de transaction invalide');
      }

      await _firestore.runTransaction((transaction) async {
        // 1. Récupérer la transaction échouée
        final originalDocRef = _firestore.collection('transactions').doc(transactionId);
        final originalDoc = await transaction.get(originalDocRef);
        
        if (!originalDoc.exists) {
          throw AppError(message: 'Transaction non trouvée');
        }
        
        final failedTransaction = TransactionModel.fromFirestore(originalDoc);
        
        if (failedTransaction.status != TransactionStatus.failed) {
          throw AppError(message: 'Cette transaction ne peut pas être relancée');
        }

        // 2. Vérifier le solde
        final senderDocRef = _firestore.collection('users').doc(failedTransaction.fromUserId);
        final senderDoc = await transaction.get(senderDocRef);
        
        if (!senderDoc.exists) {
          throw AppError(message: 'Compte expéditeur non trouvé');
        }
        
        final currentBalance = (senderDoc.data()?['balance'] ?? 0.0).toDouble();
        
        if (currentBalance < failedTransaction.amount) {
          throw AppError(message: 'Solde insuffisant');
        }

        // 3. Créer une nouvelle transaction
        final newTransactionRef = _firestore.collection('transactions').doc();
        final newTransactionData = {
          'id': newTransactionRef.id,
          'fromUserId': failedTransaction.fromUserId,
          'toUserId': toUserId,
          'amount': failedTransaction.amount,
          'type': failedTransaction.type.toString().split('.').last,
          'description': failedTransaction.description,
          'createdAt': FieldValue.serverTimestamp(),
          'status': TransactionStatus.success.toString().split('.').last,
          'isCancelable': false,
          'originalTransactionId': transactionId,
        };

        // 4. Mettre à jour les soldes
        transaction.update(senderDocRef, {
          'balance': FieldValue.increment(-failedTransaction.amount)
        });
        
        transaction.update(
          _firestore.collection('users').doc(toUserId),
          {'balance': FieldValue.increment(failedTransaction.amount)}
        );
        
        // 5. Créer la nouvelle transaction
        transaction.set(newTransactionRef, newTransactionData);

        // 6. Supprimer l'ancienne transaction
        transaction.delete(originalDocRef);

        // 7. Créer une notification de succès
        final notificationRef = _firestore.collection('notifications').doc();
        transaction.set(notificationRef, {
          'userId': failedTransaction.fromUserId,
          'title': 'Transfert réussi',
          'message': 'Le transfert de ${failedTransaction.amount} FCFA a été effectué avec succès',
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      });
    } catch (e) {
      print('Erreur lors de la relance: $e');
      throw ErrorHandler.handleFirebaseError(e);
    }
  }
} 
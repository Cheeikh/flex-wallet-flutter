// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../data/models/recurring_transfer_model.dart';
// import 'package:get/get.dart';
// import '../modules/client/controllers/client_controller.dart';
// import 'dart:async';
// import 'package:flutter/material.dart';
// import '../providers/transfer_provider.dart';

// class RecurringTransferService extends GetxService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final TransferProvider _transferProvider = Get.find<TransferProvider>();
//   Timer? _timer;
//   final _processingTransfers = <String>{};

//   @override
//   void onInit() {
//     super.onInit();
//     // Vérifier les transferts toutes les minutes
//     _timer = Timer.periodic(const Duration(minutes: 1), (_) {
//       _checkAndExecuteTransfers();
//     });
//   }

//   @override
//   void onClose() {
//     _timer?.cancel();
//     super.onClose();
//   }

//   Future<void> _checkAndExecuteTransfers() async {
//     try {
//       final now = DateTime.now();
      
//       // Récupérer tous les transferts récurrents actifs
//       final snapshot = await _firestore
//           .collection('recurring_transfers')
//           .where('isActive', isEqualTo: true)
//           .get();

//       for (var doc in snapshot.docs) {
//         final transfer = RecurringTransferModel.fromFirestore(doc);
        
//         // Éviter le traitement multiple du même transfert
//         if (_processingTransfers.contains(transfer.id)) continue;

//         if (_shouldExecuteNow(transfer, now)) {
//           _processingTransfers.add(transfer.id);
          
//           try {
//             await _executeTransfer(transfer);
            
//             // Mettre à jour la date de dernière exécution
//             await _firestore
//                 .collection('recurring_transfers')
//                 .doc(transfer.id)
//                 .update({
//               'lastExecuted': Timestamp.fromDate(now),
//             });
//           } finally {
//             _processingTransfers.remove(transfer.id);
//           }
//         }
//       }
//     } catch (e) {
//       print('Erreur lors de la vérification des transferts récurrents: $e');
//     }
//   }

//   bool _shouldExecuteNow(RecurringTransferModel transfer, DateTime now) {
//     // Vérifier si le transfert est actif et dans la période valide
//     if (!transfer.isActive) return false;
//     if (now.isBefore(transfer.startDate)) return false;
//     if (transfer.endDate != null && now.isAfter(transfer.endDate!)) return false;

//     // Vérifier l'heure d'exécution
//     if (now.hour != transfer.executionTime.hour || 
//         now.minute != transfer.executionTime.minute) {
//       return false;
//     }

//     final lastExec = transfer.lastExecuted ?? transfer.startDate;
    
//     // Vérifier la fréquence
//     switch (transfer.frequency) {
//       case RecurringFrequency.daily:
//         return now.difference(lastExec).inDays >= 1;
        
//       case RecurringFrequency.weekly:
//         if (now.difference(lastExec).inDays < 7) return false;
//         return now.weekday == lastExec.weekday;
        
//       case RecurringFrequency.monthly:
//         if (now.year == lastExec.year && now.month == lastExec.month) {
//           return false;
//         }
//         return now.day == lastExec.day;
        
//       case RecurringFrequency.yearly:
//         if (now.year == lastExec.year) return false;
//         return now.month == lastExec.month && now.day == lastExec.day;
//     }
//   }

//   Future<void> _executeTransfer(RecurringTransferModel transfer) async {
//     try {
//       // Utiliser le provider pour exécuter le transfert via le backend Java
//       await _transferProvider.executeTransfer(transfer);
//       print('Transfert récurrent exécuté avec succès: ${transfer.id}');
//     } catch (e) {
//       print('Erreur lors de l\'exécution du transfert récurrent: $e');
//       await _createFailureNotification(transfer, e.toString());
//     }
//   }

//   Future<void> _createFailureNotification(
//     RecurringTransferModel transfer,
//     String error,
//   ) async {
//     try {
//       await _firestore.collection('notifications').add({
//         'userId': transfer.fromUserId,
//         'title': 'Échec du transfert récurrent',
//         'message': 'Le transfert vers ${transfer.toPhone} de ${transfer.amount} FCFA a échoué: $error',
//         'type': 'recurring_transfer_failed',
//         'read': false,
//         'createdAt': FieldValue.serverTimestamp(),
//       });
//     } catch (e) {
//       print('Erreur lors de la création de la notification: $e');
//     }
//   }
// } 
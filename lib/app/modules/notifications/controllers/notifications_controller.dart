import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/notification_model.dart';
import '../../auth/controllers/auth_controller.dart';

class NotificationsController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final notifications = <NotificationModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      isLoading.value = true;
      final userId = Get.find<AuthController>().currentUser?.uid;
      if (userId == null) return;

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      notifications.value = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les notifications',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});

      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(read: true);
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de marquer la notification comme lue',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final batch = _firestore.batch();
      final userId = Get.find<AuthController>().currentUser?.uid;
      if (userId == null) return;

      final unreadDocs = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
      
      // Mettre à jour l'état local
      notifications.value = notifications.map((n) => n.copyWith(read: true)).toList();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de marquer toutes les notifications comme lues',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();

      notifications.removeWhere((n) => n.id == notificationId);
      
      Get.snackbar(
        'Succès',
        'Notification supprimée',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer la notification',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
} 
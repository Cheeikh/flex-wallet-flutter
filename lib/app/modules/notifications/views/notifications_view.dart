import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/notifications_controller.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton.icon(
            onPressed: controller.markAllAsRead,
            icon: const Icon(Icons.done_all),
            label: const Text('Tout marquer comme lu'),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune notification',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: controller.notifications.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final notification = controller.notifications[index];
            return Dismissible(
              key: Key(notification.id),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => controller.deleteNotification(notification.id),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: notification.isRead 
                      ? Colors.grey[200] 
                      : Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.notifications_outlined,
                    color: notification.isRead 
                        ? Colors.grey 
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead 
                        ? FontWeight.normal 
                        : FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification.message),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.yMMMd().add_Hm().format(notification.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                onTap: () => controller.markAsRead(notification.id),
              ),
            );
          },
        );
      }),
    );
  }
} 
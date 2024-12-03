import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class NotificationService extends GetxService {
  static NotificationService get to => Get.find();

  void showSuccess({
    required String message,
    String? title,
    Duration? duration,
  }) {
    Get.snackbar(
      title ?? 'Succès',
      message,
      backgroundColor: AppTheme.successColor.withOpacity(0.1),
      colorText: AppTheme.successColor,
      snackPosition: SnackPosition.TOP,
      duration: duration ?? const Duration(seconds: 3),
      margin: const EdgeInsets.all(8),
      icon: const Icon(Icons.check_circle, color: AppTheme.successColor),
    );
  }

  void showError({
    required String message,
    String? title,
    Duration? duration,
  }) {
    Get.snackbar(
      title ?? 'Erreur',
      message,
      backgroundColor: AppTheme.errorColor.withOpacity(0.1),
      colorText: AppTheme.errorColor,
      snackPosition: SnackPosition.TOP,
      duration: duration ?? const Duration(seconds: 3),
      margin: const EdgeInsets.all(8),
      icon: const Icon(Icons.error, color: AppTheme.errorColor),
    );
  }

  void showWarning({
    required String message,
    String? title,
    Duration? duration,
  }) {
    Get.snackbar(
      title ?? 'Attention',
      message,
      backgroundColor: AppTheme.warningColor.withOpacity(0.1),
      colorText: AppTheme.warningColor,
      snackPosition: SnackPosition.TOP,
      duration: duration ?? const Duration(seconds: 3),
      margin: const EdgeInsets.all(8),
      icon: const Icon(Icons.warning, color: AppTheme.warningColor),
    );
  }

  void showInfo({
    required String message,
    String? title,
    Duration? duration,
  }) {
    Get.snackbar(
      title ?? 'Information',
      message,
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      colorText: AppTheme.primaryColor,
      snackPosition: SnackPosition.TOP,
      duration: duration ?? const Duration(seconds: 3),
      margin: const EdgeInsets.all(8),
      icon: const Icon(Icons.info, color: AppTheme.primaryColor),
    );
  }

  Future<bool?> showConfirmation({
    required String message,
    String? title,
    String? confirmText,
    String? cancelText,
  }) async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: Text(title ?? 'Confirmation'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText ?? 'Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: Text(confirmText ?? 'Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> showLoading({
    String? message,
    bool barrierDismissible = false,
  }) async {
    await Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message),
            ],
          ],
        ),
      ),
      barrierDismissible: barrierDismissible,
    );
  }

  void hideLoading() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }
} 
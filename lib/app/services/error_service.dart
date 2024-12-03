import 'package:get/get.dart';
import '../core/utils/error_handler.dart';
import '../core/utils/app_error.dart';
import 'notification_service.dart';

class ErrorService extends GetxService {
  void handleError(dynamic error, {String? context}) {
    final AppError appError = ErrorHandler.handleFirebaseError(error);
    
    NotificationService.to.showError(
      message: appError.message,
      title: context,
    );

    // Log l'erreur pour le débogage
    print('Error ($context): ${appError.message}');
    print('Original error: ${appError.originalError}');
  }
} 
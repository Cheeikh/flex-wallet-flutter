import 'app_error.dart';

class ErrorHandler {
  static AppError handleFirebaseError(dynamic error) {
    String message = 'Une erreur est survenue';
    
    if (error is String) {
      message = error;
    }
    
    return AppError(
      message: message,
      originalError: error,
    );
  }
} 
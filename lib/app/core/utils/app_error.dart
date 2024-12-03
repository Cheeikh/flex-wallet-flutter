class AppError implements Exception {
  final String message;
  final dynamic originalError;

  AppError({
    required this.message,
    this.originalError,
  });
} 
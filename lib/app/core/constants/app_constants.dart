class AppConstants {
  // Messages
  static const String errorUserNotFound = 'Utilisateur non trouvé';
  static const String errorInsufficientBalance = 'Solde insuffisant';
  static const String errorLoadingTransactions = 'Impossible de charger les transactions';
  static const String errorLoadingBalance = 'Impossible de charger le solde';
  static const String errorInvalidQRCode = 'QR Code invalide';
  
  // Limites
  static const double defaultMaxBalance = 1000000.0;
  static const double defaultTransactionLimit = 100000.0;
  static const int maxRecurringTransfers = 10;
  
  // Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String currencyLocale = 'fr_FR';
  static const String currencySymbol = 'FCFA';
  
  // Collections Firestore
  static const String usersCollection = 'users';
  static const String transactionsCollection = 'transactions';
  static const String recurringTransfersCollection = 'recurring_transfers';
} 
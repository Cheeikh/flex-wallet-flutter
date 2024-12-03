import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class CacheService extends GetxController {
  final _box = GetStorage();

  Future<void> saveTransactions(List<Map<String, dynamic>> transactions) async {
    await _box.write('transactions', transactions);
  }

  List<Map<String, dynamic>> getTransactions() {
    final data = _box.read('transactions');
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _box.write('user_data', userData);
  }

  Map<String, dynamic>? getUserData() {
    final data = _box.read('user_data');
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  Future<void> clearCache() async {
    await _box.erase();
  }

  // Méthodes pour la gestion du cache hors ligne
  Future<void> saveOfflineTransactions(List<Map<String, dynamic>> transactions) async {
    await _box.write('offline_transactions', transactions);
  }

  List<Map<String, dynamic>> getOfflineTransactions() {
    final data = _box.read('offline_transactions');
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> clearOfflineTransactions() async {
    await _box.remove('offline_transactions');
  }

  // Méthodes pour la gestion des préférences utilisateur
  Future<void> saveThemeMode(bool isDarkMode) async {
    await _box.write('theme_mode', isDarkMode);
  }

  bool getThemeMode() {
    return _box.read('theme_mode') ?? false;
  }

  Future<void> saveLanguage(String languageCode) async {
    await _box.write('language', languageCode);
  }

  String getLanguage() {
    return _box.read('language') ?? 'fr';
  }
} 
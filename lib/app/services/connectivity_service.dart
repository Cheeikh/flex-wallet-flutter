import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'dart:async';

class ConnectivityService extends GetxService {
  final _isConnected = true.obs;
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  bool get isConnected => _isConnected.value;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.isNotEmpty) {
        _updateConnectionStatus(results.first);
      }
    });
  }

  Future<void> _initConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (results.isNotEmpty) {
      _updateConnectionStatus(results.first);
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _isConnected.value = result != ConnectivityResult.none;
    if (!_isConnected.value) {
      Get.snackbar(
        'Pas de connexion',
        'Vérifiez votre connexion internet',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }
} 
import 'package:get/get.dart';
import '../../services/user_service.dart';
// ... autres imports

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // ... autres services
    Get.put(UserService());  // Ajouter cette ligne
  }
} 
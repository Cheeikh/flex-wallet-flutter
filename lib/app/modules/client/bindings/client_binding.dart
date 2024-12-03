import 'package:get/get.dart';
import '../controllers/client_controller.dart';
import '../../../providers/transfer_provider.dart';

class ClientBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TransferProvider());
    Get.lazyPut(() => ClientController());
  }
} 
import 'package:get/get.dart';
import 'providers/transfer_provider.dart';

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TransferProvider(), fenix: true);
  }
} 
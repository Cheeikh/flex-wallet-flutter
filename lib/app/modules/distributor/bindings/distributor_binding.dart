import 'package:get/get.dart';
import '../controllers/distributor_controller.dart';

class DistributorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DistributorController>(
      () => DistributorController(),
    );
  }
} 
import 'package:get/get.dart';

import '../controllers/instance_ekskul_controller.dart';

class InstanceEkskulBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InstanceEkskulController>(
      () => InstanceEkskulController(),
    );
  }
}

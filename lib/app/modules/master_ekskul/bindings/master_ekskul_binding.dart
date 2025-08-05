import 'package:get/get.dart';

import '../controllers/master_ekskul_controller.dart';

class MasterEkskulBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MasterEkskulController>(
      () => MasterEkskulController(),
    );
  }
}

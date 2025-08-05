import 'package:get/get.dart';

import '../controllers/manajemen_ekskul_controller.dart';

class ManajemenEkskulBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManajemenEkskulController>(
      () => ManajemenEkskulController(),
    );
  }
}

import 'package:get/get.dart';

import '../controllers/manajemen_jabatan_controller.dart';

class ManajemenJabatanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManajemenJabatanController>(
      () => ManajemenJabatanController(),
    );
  }
}

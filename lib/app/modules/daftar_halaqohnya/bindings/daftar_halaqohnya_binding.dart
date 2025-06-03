import 'package:get/get.dart';

import '../controllers/daftar_halaqohnya_controller.dart';

class DaftarHalaqohnyaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DaftarHalaqohnyaController>(
      () => DaftarHalaqohnyaController(),
    );
  }
}

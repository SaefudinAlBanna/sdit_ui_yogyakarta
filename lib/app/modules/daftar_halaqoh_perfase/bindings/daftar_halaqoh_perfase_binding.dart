import 'package:get/get.dart';

import '../controllers/daftar_halaqoh_perfase_controller.dart';

class DaftarHalaqohPerfaseBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DaftarHalaqohPerfaseController>(
      () => DaftarHalaqohPerfaseController(),
    );
  }
}

import 'package:get/get.dart';

import '../controllers/daftar_halaqoh_controller.dart';

class DaftarHalaqohBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DaftarHalaqohController>(
      () => DaftarHalaqohController(),
    );
  }
}

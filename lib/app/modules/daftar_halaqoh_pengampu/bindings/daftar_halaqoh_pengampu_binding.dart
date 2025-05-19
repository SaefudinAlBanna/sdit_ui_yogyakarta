import 'package:get/get.dart';

import '../controllers/daftar_halaqoh_pengampu_controller.dart';

class DaftarHalaqohPengampuBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DaftarHalaqohPengampuController>(
      () => DaftarHalaqohPengampuController(),
    );
  }
}

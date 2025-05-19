import 'package:get/get.dart';

import '../controllers/daftar_kelas_controller.dart';

class DaftarKelasBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DaftarKelasController>(
      () => DaftarKelasController(),
    );
  }
}

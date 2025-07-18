import 'package:get/get.dart';

import '../controllers/daftar_ekskul_controller.dart';

class DaftarEkskulBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DaftarEkskulController>(
      () => DaftarEkskulController(),
    );
  }
}

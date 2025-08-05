import 'package:get/get.dart';

import '../controllers/daftar_informasi_controller.dart';

class DaftarInformasiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DaftarInformasiController>(
      () => DaftarInformasiController(),
    );
  }
}

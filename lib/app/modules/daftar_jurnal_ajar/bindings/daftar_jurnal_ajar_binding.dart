import 'package:get/get.dart';

import '../controllers/daftar_jurnal_ajar_controller.dart';

class DaftarJurnalAjarBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DaftarJurnalAjarController>(
      () => DaftarJurnalAjarController(),
    );
  }
}

import 'package:get/get.dart';

import '../controllers/laporan_ekskul_controller.dart';

class LaporanEkskulBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LaporanEkskulController>(
      () => LaporanEkskulController(),
    );
  }
}

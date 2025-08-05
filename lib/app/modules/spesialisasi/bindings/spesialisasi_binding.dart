import 'package:get/get.dart';

import '../controllers/spesialisasi_controller.dart';

class SpesialisasiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SpesialisasiController>(
      () => SpesialisasiController(),
    );
  }
}

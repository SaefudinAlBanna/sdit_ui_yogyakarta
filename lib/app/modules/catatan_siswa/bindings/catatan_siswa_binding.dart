import 'package:get/get.dart';

import '../controllers/catatan_siswa_controller.dart';

class CatatanSiswaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CatatanSiswaController>(
      () => CatatanSiswaController(),
    );
  }
}

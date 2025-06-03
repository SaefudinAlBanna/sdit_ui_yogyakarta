import 'package:get/get.dart';

import '../controllers/input_catatan_khusus_siswa_controller.dart';

class InputCatatanKhususSiswaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InputCatatanKhususSiswaController>(
      () => InputCatatanKhususSiswaController(),
    );
  }
}

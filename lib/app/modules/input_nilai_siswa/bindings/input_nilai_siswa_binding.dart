import 'package:get/get.dart';

import '../controllers/input_nilai_siswa_controller.dart';

class InputNilaiSiswaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InputNilaiSiswaController>(
      () => InputNilaiSiswaController(),
    );
  }
}

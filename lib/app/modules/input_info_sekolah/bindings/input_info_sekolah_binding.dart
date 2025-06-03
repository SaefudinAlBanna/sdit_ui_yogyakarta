import 'package:get/get.dart';

import '../controllers/input_info_sekolah_controller.dart';

class InputInfoSekolahBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InputInfoSekolahController>(
      () => InputInfoSekolahController(),
    );
  }
}

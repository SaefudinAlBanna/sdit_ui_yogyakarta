import 'package:get/get.dart';

import '../controllers/laksanakan_ujian_controller.dart';

class LaksanakanUjianBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LaksanakanUjianController>(
      () => LaksanakanUjianController(),
    );
  }
}

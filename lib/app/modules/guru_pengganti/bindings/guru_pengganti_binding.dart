import 'package:get/get.dart';

import '../controllers/guru_pengganti_controller.dart';

class GuruPenggantiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GuruPenggantiController>(
      () => GuruPenggantiController(),
    );
  }
}

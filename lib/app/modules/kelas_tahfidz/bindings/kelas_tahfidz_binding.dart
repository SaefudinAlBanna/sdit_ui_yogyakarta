import 'package:get/get.dart';

import '../controllers/kelas_tahfidz_controller.dart';

class KelasTahfidzBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<KelasTahfidzController>(
      () => KelasTahfidzController(),
    );
  }
}

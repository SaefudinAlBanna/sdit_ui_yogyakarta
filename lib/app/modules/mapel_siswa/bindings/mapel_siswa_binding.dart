import 'package:get/get.dart';

import '../controllers/mapel_siswa_controller.dart';

class MapelSiswaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MapelSiswaController>(
      () => MapelSiswaController(),
    );
  }
}

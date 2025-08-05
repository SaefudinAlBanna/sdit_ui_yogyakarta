import 'package:get/get.dart';

import '../controllers/halaman_pengganti_controller.dart';

class HalamanPenggantiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HalamanPenggantiController>(
      () => HalamanPenggantiController(),
    );
  }
}

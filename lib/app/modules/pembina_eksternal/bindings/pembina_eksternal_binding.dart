import 'package:get/get.dart';

import '../controllers/pembina_eksternal_controller.dart';

class PembinaEksternalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PembinaEksternalController>(
      () => PembinaEksternalController(),
    );
  }
}

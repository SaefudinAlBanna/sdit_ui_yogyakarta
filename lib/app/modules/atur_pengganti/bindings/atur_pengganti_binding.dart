import 'package:get/get.dart';

import '../controllers/atur_pengganti_controller.dart';

class AturPenggantiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AturPenggantiController>(
      () => AturPenggantiController(),
    );
  }
}

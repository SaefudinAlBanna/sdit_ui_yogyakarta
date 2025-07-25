import 'package:get/get.dart';

import '../controllers/analisis_akademik_controller.dart';

class AnalisisAkademikBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AnalisisAkademikController>(
      () => AnalisisAkademikController(),
    );
  }
}

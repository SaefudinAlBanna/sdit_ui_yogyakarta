import 'package:get/get.dart';

import '../controllers/kalender_akademik_controller.dart';

class KalenderAkademikBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<KalenderAkademikController>(
      () => KalenderAkademikController(),
    );
  }
}

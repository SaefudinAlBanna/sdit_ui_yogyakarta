import 'package:get/get.dart';

import '../controllers/jurnal_ajar_harian_controller.dart';

class JurnalAjarHarianBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JurnalAjarHarianController>(
      () => JurnalAjarHarianController(),
    );
  }
}

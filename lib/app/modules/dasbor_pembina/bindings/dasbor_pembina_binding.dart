import 'package:get/get.dart';

import '../controllers/dasbor_pembina_controller.dart';

class DasborPembinaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DasborPembinaController>(
      () => DasborPembinaController(),
    );
  }
}

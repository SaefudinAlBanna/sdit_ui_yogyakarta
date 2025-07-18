import 'package:get/get.dart';

import '../controllers/tanggapan_catatan_controller.dart';

class TanggapanCatatanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TanggapanCatatanController>(
      () => TanggapanCatatanController(),
    );
  }
}

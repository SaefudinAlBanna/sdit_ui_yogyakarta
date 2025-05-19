import 'package:get/get.dart';

import '../controllers/pemberian_nilai_halaqoh_controller.dart';

class PemberianNilaiHalaqohBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PemberianNilaiHalaqohController>(
      () => PemberianNilaiHalaqohController(),
    );
  }
}

import 'package:get/get.dart';

import '../controllers/detail_nilai_halaqoh_controller.dart';

class DetailNilaiHalaqohBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DetailNilaiHalaqohController>(
      () => DetailNilaiHalaqohController(),
    );
  }
}

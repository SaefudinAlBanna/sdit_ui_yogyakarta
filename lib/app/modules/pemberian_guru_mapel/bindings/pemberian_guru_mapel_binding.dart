import 'package:get/get.dart';

import '../controllers/pemberian_guru_mapel_controller.dart';

class PemberianGuruMapelBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PemberianGuruMapelController>(
      () => PemberianGuruMapelController(),
    );
  }
}

import 'package:get/get.dart';

import '../controllers/pantau_tahfidz_controller.dart';

class PantauTahfidzBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PantauTahfidzController>(
      () => PantauTahfidzController(),
    );
  }
}

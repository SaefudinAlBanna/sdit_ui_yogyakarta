import 'package:get/get.dart';

import '../controllers/manajemen_jam_controller.dart';

class ManajemenJamBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManajemenJamController>(
      () => ManajemenJamController(),
    );
  }
}

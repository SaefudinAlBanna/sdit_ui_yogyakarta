import 'package:get/get.dart';

import '../controllers/kurikulum_master_controller.dart';

class KurikulumMasterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<KurikulumMasterController>(
      () => KurikulumMasterController(),
    );
  }
}

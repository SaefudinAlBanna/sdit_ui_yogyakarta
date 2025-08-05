import 'package:get/get.dart';

import '../controllers/manajemen_tahun_ajaran_ekskul_controller.dart';

class ManajemenTahunAjaranEkskulBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManajemenTahunAjaranEkskulController>(
      () => ManajemenTahunAjaranEkskulController(),
    );
  }
}

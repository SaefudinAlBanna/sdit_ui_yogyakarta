import 'package:get/get.dart';

import '../controllers/tambah_kelompok_mengaji_controller.dart';

class TambahKelompokMengajiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TambahKelompokMengajiController>(
      () => TambahKelompokMengajiController(),
    );
  }
}

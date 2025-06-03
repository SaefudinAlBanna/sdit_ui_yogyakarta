import 'package:get/get.dart';

import '../controllers/tanggapan_catatan_khusus_siswa_controller.dart';

class TanggapanCatatanKhususSiswaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TanggapanCatatanKhususSiswaController>(
      () => TanggapanCatatanKhususSiswaController(),
    );
  }
}

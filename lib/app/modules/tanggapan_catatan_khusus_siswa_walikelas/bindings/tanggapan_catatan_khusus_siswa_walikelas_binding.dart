import 'package:get/get.dart';

import '../controllers/tanggapan_catatan_khusus_siswa_walikelas_controller.dart';

class TanggapanCatatanKhususSiswaWalikelasBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TanggapanCatatanKhususSiswaWalikelasController>(
      () => TanggapanCatatanKhususSiswaWalikelasController(),
    );
  }
}

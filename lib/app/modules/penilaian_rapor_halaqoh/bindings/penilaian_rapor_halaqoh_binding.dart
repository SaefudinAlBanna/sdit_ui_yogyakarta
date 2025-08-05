// File: lib/app/modules/penilaian_rapor_halaqoh/bindings/penilaian_rapor_halaqoh_binding.dart

import 'package:get/get.dart';
import '../controllers/penilaian_rapor_halaqoh_controller.dart';

class PenilaianRaporHalaqohBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Ambil seluruh argumen yang dikirim dalam bentuk Map.
    final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;

    // 2. Langsung teruskan seluruh Map argumen ke controller.
    //    Controller akan bertanggung jawab untuk "membongkar" isinya.
    Get.lazyPut<PenilaianRaporHalaqohController>(
      () => PenilaianRaporHalaqohController(argumenNavigasi: args),
    );
  }
}
// File: lib/app/modules/penilaian_rapor_ekskul/bindings/penilaian_rapor_ekskul_binding.dart

import 'package:get/get.dart';
import '../controllers/penilaian_rapor_ekskul_controller.dart';

class PenilaianRaporEkskulBinding extends Bindings {
  @override
  void dependencies() {
    // Ambil ID ekskul dari argumen navigasi
    final String instanceEkskulId = Get.arguments as String;
    
    Get.lazyPut<PenilaianRaporEkskulController>(
      () => PenilaianRaporEkskulController(instanceEkskulId: instanceEkskulId),
    );
  }
}
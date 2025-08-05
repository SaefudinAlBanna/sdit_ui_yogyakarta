// File: lib/app/modules/kelola_catatan_rapor/bindings/kelola_catatan_rapor_binding.dart

import 'package:get/get.dart';
import '../controllers/kelola_catatan_rapor_controller.dart';

class KelolaCatatanRaporBinding extends Bindings {
  @override
  void dependencies() {
    // Ambil ID Kelas dari argumen navigasi
    final String idKelas = Get.arguments as String;

    Get.lazyPut<KelolaCatatanRaporController>(
      () => KelolaCatatanRaporController(idKelas: idKelas),
    );
  }
}
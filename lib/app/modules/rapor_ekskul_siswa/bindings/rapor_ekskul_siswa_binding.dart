import 'package:get/get.dart';
import '../../../models/siswa_model.dart';
import '../controllers/rapor_ekskul_siswa_controller.dart';

class RaporEkskulSiswaBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Ambil objek SiswaModel dari argumen yang dikirim saat navigasi.
    final SiswaModel siswa = Get.arguments as SiswaModel;
    
    // 2. Masukkan objek 'siswa' ke dalam controller saat controller dibuat.
    Get.lazyPut<RaporEkskulViewController>(
      () => RaporEkskulViewController(siswa: siswa),
    );
  }
}
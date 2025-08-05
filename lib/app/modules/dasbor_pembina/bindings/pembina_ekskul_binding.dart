import 'package:get/get.dart';
import '../controllers/pembina_ekskul_controller.dart';

class PembinaEkskulDetailBinding extends Bindings {
  @override
  void dependencies() {
    // Ambil instanceEkskulId dari argumen navigasi
    final String instanceEkskulId = Get.arguments['instanceEkskulId'];
    
    Get.lazyPut<PembinaEkskulController>(
      () => PembinaEkskulController(instanceEkskulId: instanceEkskulId),
    );
  }
}
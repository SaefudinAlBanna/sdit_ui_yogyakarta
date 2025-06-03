import 'package:get/get.dart';

import '../controllers/buat_jadwal_pelajaran_controller.dart';

class BuatJadwalPelajaranBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BuatJadwalPelajaranController>(
      () => BuatJadwalPelajaranController(),
    );
  }
}

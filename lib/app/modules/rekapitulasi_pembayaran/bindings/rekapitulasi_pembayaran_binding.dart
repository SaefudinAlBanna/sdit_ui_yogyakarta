import 'package:get/get.dart';

import '../controllers/rekapitulasi_pembayaran_controller.dart';

class RekapitulasiPembayaranBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RekapitulasiPembayaranController>(
      () => RekapitulasiPembayaranController(),
    );
  }
}

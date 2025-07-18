import 'package:get/get.dart';

import '../controllers/rekapitulasi_pembayaran_rinci_controller.dart';

class RekapitulasiPembayaranRinciBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RekapitulasiPembayaranRinciController>(
      () => RekapitulasiPembayaranRinciController(),
    );
  }
}

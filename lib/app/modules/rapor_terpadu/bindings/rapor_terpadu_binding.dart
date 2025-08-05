import 'package:get/get.dart';
import '../controllers/rapor_terpadu_controller.dart';

class RaporTerpaduBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RaporTerpaduController>(
      () => RaporTerpaduController(),
    );
  }
}
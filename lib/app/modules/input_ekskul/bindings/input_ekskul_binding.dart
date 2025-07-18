import 'package:get/get.dart';

import '../controllers/input_ekskul_controller.dart';

class InputEkskulBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InputEkskulController>(
      () => InputEkskulController(),
    );
  }
}

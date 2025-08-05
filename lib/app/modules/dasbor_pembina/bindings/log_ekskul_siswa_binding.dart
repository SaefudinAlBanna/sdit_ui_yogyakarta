import 'package:get/get.dart';
// import 'package:sdit_ui_yogyakarta/app/modules/admin_manajemen/models/siswa_model.dart';
import '../../../models/siswa_model.dart';
import '../controllers/log_ekskul_siswa_controller.dart';

class LogEkskulSiswaBinding extends Bindings {
  @override
  void dependencies() {
    final String instanceEkskulId = Get.arguments['instanceEkskulId'];
    final SiswaModel siswa = Get.arguments['siswa'];
    
    Get.lazyPut<LogEkskulSiswaController>(
      () => LogEkskulSiswaController(instanceEkskulId: instanceEkskulId, siswa: siswa),
    );
  }
}
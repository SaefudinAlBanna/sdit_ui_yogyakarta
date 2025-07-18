import 'package:get/get.dart';

import '../controllers/import_siswa_excel_controller.dart';

class ImportSiswaExcelBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ImportSiswaExcelController>(
      () => ImportSiswaExcelController(),
    );
  }
}

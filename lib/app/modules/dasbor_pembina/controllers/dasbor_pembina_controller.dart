// File: lib/app/modules/pembina_area/controllers/dasbor_pembina_controller.dart

import 'package:get/get.dart';
import 'package:sdit_ui_yogyakarta/app/modules/home/controllers/home_controller.dart';

class DasborPembinaController extends GetxController {
  // Ambil HomeController yang sudah berisi semua data pengguna
  final HomeController homeC = Get.find<HomeController>();

  // Tidak perlu state loading atau list baru, karena kita akan langsung
  // mereferensikan state yang sudah ada di HomeController untuk efisiensi.
}
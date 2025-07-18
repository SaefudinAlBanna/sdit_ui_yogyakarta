// lib/app/modules/rekap_jurnal_admin/controllers/rekap_jurnal_admin_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

// Import HomeController untuk mengakses data semester global
import '../../home/controllers/home_controller.dart';

class RekapJurnalAdminController extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  // Ambil instance HomeController yang sudah ada di memori
  final HomeController homeController = Get.find<HomeController>();

  /// [VERSI BARU] Mengambil SEMUA jurnal dari SEMUA guru,
  /// difilter berdasarkan semester yang sedang aktif.
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllJurnalRekap() {
    // Ambil data global yang dibutuhkan
    final String semesterAktif = homeController.semesterAktifId.value;
    final String idSekolah = homeController.idSekolah; // Ambil idSekolah dari HomeController

    // Pengaman: Jika semester belum siap, jangan jalankan query.
    if (semesterAktif.isEmpty) {
      return Stream.empty();
    }

    // Query ke koleksi `jurnal_flat` yang sudah dioptimalkan.
    return firestore
        .collection('Sekolah')
        .doc(idSekolah) // Gunakan idSekolah
        .collection('jurnal_flat') // <-- Targetkan koleksi flat ini
        .where('semester', isEqualTo: semesterAktif) // <-- FILTER SEMESTER
        .orderBy('timestamp', descending: true) // Gunakan field timestamp
        .snapshots();
  }
}
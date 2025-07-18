// lib/app/modules/rekap_jurnal_guru/controllers/rekap_jurnal_guru_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../home/controllers/home_controller.dart';

class RekapJurnalGuruController extends GetxController {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeController = Get.find<HomeController>();

  /// [VERSI FINAL] Mengambil rekap jurnal guru dari koleksi `jurnal_flat` yang dioptimalkan.
  Stream<QuerySnapshot<Map<String, dynamic>>> getRekapJurnalGuru() {
    final String idUser = auth.currentUser!.uid;
    final String semesterAktif = homeController.semesterAktifId.value;

    // Jika semester belum siap, jangan jalankan query.
    if (semesterAktif.isEmpty) {
      return Stream.empty();
    }

    // Query ke `jurnal_flat` jauh lebih sederhana dan cepat.
    return firestore
        .collection('Sekolah')
        .doc(homeController.idSekolah)
        .collection('jurnal_flat') // <-- Targetkan koleksi flat ini
        .where('idpenginput', isEqualTo: idUser)
        .where('semester', isEqualTo: semesterAktif)
        .orderBy('timestamp', descending: true) // Gunakan field timestamp
        .snapshots();
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get/get.dart';
// import 'package:flutter/material.dart';

// // Import HomeController untuk mengakses data semester
// import '../../home/controllers/home_controller.dart';

// class RekapJurnalGuruController extends GetxController {
//   final FirebaseAuth auth = FirebaseAuth.instance;
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
//   // Ambil instance HomeController yang sudah ada
//   final HomeController homeController = Get.find<HomeController>();

//   /// [DIPERBARUI] Mengambil rekap jurnal guru berdasarkan semester yang aktif.
//   Stream<QuerySnapshot<Map<String, dynamic>>> getRekapJurnalGuru() {
//     final String idUser = auth.currentUser!.uid;
//     final String semesterAktif = homeController.semesterAktifId.value;

//     // --- TAMBAHKAN BLOK DEBUG INI ---
//     debugPrint("========================================");
//     debugPrint("MEMBUAT QUERY UNTUK REKAP JURNAL GURU");
//     debugPrint("idUser: '$idUser' (Tipe: ${idUser.runtimeType})");
//     debugPrint("semesterAktif: '$semesterAktif' (Tipe: ${semesterAktif.runtimeType})");
//     debugPrint("========================================");
//     // ------------------------------------

//     // --- TAMBAHKAN PENGECEKAN KEAMANAN ---
//     // Jika karena suatu alasan semester masih kosong, jangan jalankan query.
//     // Ini akan mencegah error dan menampilkan halaman kosong saja.
//     if (semesterAktif.isEmpty || semesterAktif == "1") {
//        if (semesterAktif.isEmpty) {
//         debugPrint("QUERY DIBATALKAN: semesterAktif masih kosong!");
//         return Stream.empty(); // Kembalikan stream kosong agar tidak error
//       }
//     }
//     // ------------------------------------

//     return firestore
//         .collectionGroup('jurnalkelas')
//         .where('idpenginput', isEqualTo: idUser)
//         .where('semester', isEqualTo: semesterAktif)
//         .orderBy('tanggalinput', descending: true)
//         .snapshots();
//   }
// }
// lib/app/modules/laksanakan_ujian/controllers/laksanakan_ujian_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../home/controllers/home_controller.dart';
import '../../../models/siswa_ujian.dart'; // <-- Buat model baru ini

class LaksanakanUjianController extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeController = Get.find<HomeController>();

  final RxBool isDialogLoading = false.obs;
  final TextEditingController catatanPengujiC = TextEditingController();

  /// Mengambil semua siswa dari semua kelompok yang statusnya 'siap_ujian'
  Stream<List<SiswaUjian>> getSiswaSiapUjian() {
    final semester = homeController.semesterAktifId.value;
    return firestore
        .collectionGroup('ujian')
        .where('status_ujian', isEqualTo: 'siap_ujian')
        .where('semester', isEqualTo: semester)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SiswaUjian.fromFirestore(doc))
            .toList());
  }

  /// Memproses hasil ujian (Lulus / Tidak Lulus)
  Future<void> prosesHasilUjian(SiswaUjian siswa, bool isLulus) async {
    isDialogLoading.value = true;
    try {
      final String statusAkhir = isLulus ? 'lulus' : 'tidak_lulus';
      final batch = firestore.batch();

      // Path 1: Dokumen ujian itu sendiri
      final docUjianRef = siswa.docRef; // Ambil dari model

      // Path 2: Dokumen induk siswa di koleksi `daftarsiswa`
      final docSiswaIndukRef = docUjianRef.parent.parent;

      // Update dokumen ujian dengan hasil
      batch.update(docUjianRef, {
        'status_ujian': statusAkhir,
        'catatan_penguji': catatanPengujiC.text.trim(),
        'diuji_oleh': homeController.idUser,
        'tanggal_ujian': Timestamp.now(),
      });

      // Update status di dokumen induk siswa jika tidak null
      if (docSiswaIndukRef != null) {
        batch.update(docSiswaIndukRef, {
          'status_ujian': statusAkhir,
        });
      }

      await batch.commit();
      Get.back(); // Tutup dialog
      Get.snackbar("Berhasil", "${siswa.namaSiswa} telah ditandai $statusAkhir.");
    
    } catch (e) {
      Get.snackbar("Error", "Gagal memproses hasil ujian: $e");
    } finally {
      isDialogLoading.value = false;
      catatanPengujiC.clear();
    }
  }
}
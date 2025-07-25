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
  final TextEditingController nilaiUjianC = TextEditingController();
  final TextEditingController umiBaruC = TextEditingController();

  /// Mengambil semua siswa dari semua kelompok yang statusnya 'siap_ujian'
  Stream<List<SiswaUjian>> getSiswaSiapUjian() {
    final semester = homeController.semesterAktifId.value;
    return firestore
        .collectionGroup('ujian')
        .where('status_ujian', isEqualTo: 'siap_ujian')
        .where('semester', isEqualTo: semester)
        .snapshots()
        .asyncMap((snapshot) async { // <-- Gunakan asyncMap
          // Buat daftar Future
          final futures = snapshot.docs.map((doc) async {
            // Untuk setiap dokumen ujian, lakukan get() ke dokumen induknya
            final docIndukRef = doc.reference.parent.parent;
            final docIndukSnapshot = await docIndukRef!.get();
            
            // Panggil factory constructor dengan KEDUA dokumen
            return SiswaUjian.fromFirestore(doc, docIndukSnapshot);
          }).toList();
          
          // Tunggu semua Future (get()) selesai
          return await Future.wait(futures);
        });
  }

  Future<void> batalkanKesiapanUjian(SiswaUjian siswa) async {
    Get.defaultDialog(
      title: "Konfirmasi Pembatalan",
      middleText: "Anda yakin ingin membatalkan status 'Siap Ujian' untuk ${siswa.namaSiswa}?",
      textConfirm: "Ya, Batalkan",
      textCancel: "Tidak",
      confirmTextColor: Colors.white,
      buttonColor: Colors.orange.shade800,
      onConfirm: () async {
        Get.back(); // Tutup dialog
        isDialogLoading.value = true;
        try {
          final batch = firestore.batch();

          // Path 1: Dokumen ujian itu sendiri (yang Anda hapus manual)
          final docUjianRef = siswa.docRef;

          // Path 2: Dokumen induk siswa di koleksi `daftarsiswa`
          final docSiswaIndukRef = docUjianRef.parent.parent; 

          // 1. Hapus dokumen "tiket" ujian
          batch.delete(docUjianRef);

          // 2. Turunkan "bendera" status di dokumen induk
          // Menggunakan `FieldValue.delete()` akan menghapus field `status_ujian`
          // Ini lebih bersih daripada mengisinya dengan null.
          batch.update(docSiswaIndukRef!, {
            'status_ujian': FieldValue.delete(),
          });

          await batch.commit();
          Get.snackbar("Berhasil", "Status ujian untuk ${siswa.namaSiswa} telah dibatalkan.");
          // Tidak perlu refresh, stream akan otomatis update.
        
        } catch (e) {
          Get.snackbar("Error", "Gagal membatalkan status: $e");
        } finally {
          isDialogLoading.value = false;
        }
      }
    );
  }

  /// Memproses hasil ujian (Lulus / Tidak Lulus)
  Future<void> prosesHasilUjian(SiswaUjian siswa, bool isLulus, {String? levelUmiBaru}) async {
    isDialogLoading.value = true;
    try {
      final String statusAkhir = isLulus ? 'lulus' : 'tidak_lulus';
      final batch = firestore.batch();
      final docUjianRef = siswa.docRef;
      final docSiswaIndukRef = docUjianRef.parent.parent; 
      
      batch.update(docUjianRef, {
        'status_ujian': statusAkhir,
        'catatan_penguji': catatanPengujiC.text.trim(),
        'diuji_oleh': homeController.idUser,
        'tanggal_ujian': Timestamp.now(),
        'nilai_ujian': int.tryParse(nilaiUjianC.text.trim()) ?? 0,
      });

      // --- Logika Alur Selanjutnya yang Baru ---
      if (isLulus) {
        // Jika lulus, pastikan level UMI baru ada
        if (levelUmiBaru == null || levelUmiBaru.isEmpty) {
          throw Exception("Level UMI baru wajib diisi saat siswa lulus.");
        }
        batch.update(docSiswaIndukRef!, {
          'status_ujian': FieldValue.delete(), // Hapus status agar bisa ujian lagi
          'ummi': levelUmiBaru, // <-- UPDATE UMI DENGAN DATA BARU
        });
      } else {
        // Jika tidak lulus, cukup hapus statusnya saja.
        batch.update(docSiswaIndukRef!, {
          'status_ujian': FieldValue.delete(),
        });
      }

      await batch.commit();
      
      // Tutup semua dialog yang mungkin terbuka
      if (Get.isDialogOpen!) Get.back();

      Get.snackbar("Berhasil", "${siswa.namaSiswa} telah ditandai $statusAkhir.");
    
    } catch (e) {
      Get.snackbar("Error", "Gagal memproses hasil ujian: $e");
    } finally {
      isDialogLoading.value = false;
      catatanPengujiC.clear();
      nilaiUjianC.clear();
      umiBaruC.clear();
    }
  }

  final List<String> listLevelUmi = ['Jilid 1', 'Jilid 2', 'Jilid 3', 'Jilid 4', 'Jilid 5', 'Jilid 6', 'Al-Quran', 
  'Gharib', 'Tajwid', 'Turjuman', 'Juz 30', 
  'Juz 29', 'Juz 28', 'Juz 1', 'Juz 2', 'Juz 3', 'Juz 4', 'Juz 5'];
}

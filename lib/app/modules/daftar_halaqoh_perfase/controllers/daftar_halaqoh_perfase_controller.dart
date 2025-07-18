// lib/app/modules/daftar_halaqoh_perfase/controllers/daftar_halaqoh_perfase_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../models/pengampu_info.dart';
import '../../home/controllers/home_controller.dart';

class DaftarHalaqohPerfaseController extends GetxController {
  
  // --- STATE & DEPENDENSI ---
  final Rx<String?> selectedFase = Rx<String?>(null);
  final RxBool isLoading = false.obs;
  final RxList<PengampuInfo> daftarPengampu = <PengampuInfo>[].obs;
  final List<String> listPilihanFase = ["A", "B", "C"];
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeController = Get.find<HomeController>();
  
  /// Dipanggil oleh Dropdown di View.
  void onFaseChanged(String? newValue) {
    if (newValue != null && newValue != selectedFase.value) {
      selectedFase.value = newValue;
      daftarPengampu.clear();
      loadDataPengampu();
    }
  }

  /// [FINAL & DIPERBAIKI] Menggunakan CollectionGroup dari root dan sintaks yang benar.
  Future<void> loadDataPengampu() async {
    if (selectedFase.value == null) return;
    isLoading.value = true;
    try {
      final idTahunAjaran = homeController.idTahunAjaran.value!;
      final namaDokumenFase = "Fase ${selectedFase.value}";

      // 1. [PERBAIKAN] Query collectionGroup dipanggil dari root `firestore`
      final tempatSnapshot = await firestore
          .collectionGroup('tempat') // <-- Panggil dari sini
          .where('fase', isEqualTo: namaDokumenFase) // Filter berdasarkan fase
          // Anda mungkin perlu menambahkan filter tahun ajaran jika data tahun lalu masih ada
          // .where('tahunajaran', isEqualTo: ...) 
          .get();

      if (tempatSnapshot.docs.isNotEmpty) {
        final List<Future<PengampuInfo?>> futures = tempatSnapshot.docs.map((tempatDoc) async {
          try {
            final dataTempat = tempatDoc.data();
            final String namaPengampu = dataTempat['namapengampu'];
            final String idPengampu = dataTempat['idpengampu'];
            final String namaTempat = tempatDoc.id;
            
            final semesterAktif = homeController.semesterAktifId.value;

            // [PERBAIKAN SINTAKSIS] Definisikan Future dengan benar
            Future<DocumentSnapshot<Map<String, dynamic>>> pegawaiDocFuture = 
                firestore.collection('Sekolah').doc(homeController.idSekolah)
                         .collection('pegawai').doc(idPengampu).get();

            Future<QuerySnapshot<Map<String, dynamic>>> siswaSnapshotFuture = 
                tempatDoc.reference.collection('semester').doc(semesterAktif)
                                  .collection('daftarsiswa').get();
            
            // [PERBAIKAN SINTAKSIS] Tunggu kedua Future
            final results = await Future.wait([pegawaiDocFuture, siswaSnapshotFuture]);

            // [PERBAIKAN SINTAKSIS] Casting hasil dengan aman
            final pegawaiDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
            final siswaSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;

            // [PERBAIKAN SINTAKSIS] Gunakan .data()
            final profileImageUrl = pegawaiDoc.exists && pegawaiDoc.data() != null
                ? pegawaiDoc.data()!['profileImageUrl']
                : null;
            final jumlahSiswa = siswaSnapshot.docs.length;
            
            return PengampuInfo(
              fase: namaDokumenFase,
              namaPengampu: namaPengampu,
              idPengampu: idPengampu,
              namaTempat: namaTempat,
              profileImageUrl: profileImageUrl,
              jumlahSiswa: jumlahSiswa,
            );

          } catch (e) {
            if (kDebugMode) print("Error memproses detail kelompok: $e");
            return null;
          }
        }).toList();

        final List<PengampuInfo> hasilAkhir = (await Future.wait(futures))
            .where((item) => item != null).cast<PengampuInfo>().toList();

        daftarPengampu.assignAll(hasilAkhir);
      } else {
        daftarPengampu.clear();
      }
    } catch (e) {
      if (kDebugMode) print("Error saat loadDataPengampu: $e");
      daftarPengampu.clear();
      // Tampilkan error ke pengguna jika perlu
      Get.snackbar("Error", "Gagal memuat data. Mungkin memerlukan index Firestore. Cek Debug Console.");
    } finally {
      isLoading.value = false;
    }
  }
}
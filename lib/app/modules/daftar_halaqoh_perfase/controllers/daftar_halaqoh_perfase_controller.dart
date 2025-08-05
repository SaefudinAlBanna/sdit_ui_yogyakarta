import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../models/pengampu_info.dart'; // Pastikan path ini benar
import '../../home/controllers/home_controller.dart';

class DaftarHalaqohPerfaseController extends GetxController {
  
  final Rx<String?> selectedFase = Rx<String?>(null);
  final RxBool isLoading = false.obs;
  
  final RxList<PengampuInfo> _semuaPengampu = <PengampuInfo>[].obs;
  final RxList<PengampuInfo> daftarPengampuFiltered = <PengampuInfo>[].obs;
  final TextEditingController searchC = TextEditingController();
  final RxString searchQuery = ''.obs;
  
  final List<String> listPilihanFase = ["A", "B", "C"];
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeController = Get.find<HomeController>();
  
  @override
  void onInit() {
    super.onInit();
    ever(searchQuery, (_) => _filterData());
  }

  @override
  void onClose() {
    searchC.dispose();
    super.onClose();
  }

  void onFaseChanged(String? newValue) {
    if (newValue != null && newValue != selectedFase.value) {
      selectedFase.value = newValue;
      searchC.clear();
      searchQuery.value = '';
      _semuaPengampu.clear();
      daftarPengampuFiltered.clear();
      loadDataPengampu();
    }
  }
  
  void _filterData() {
    String query = searchQuery.value.toLowerCase().trim();
    if (query.isEmpty) {
      daftarPengampuFiltered.assignAll(_semuaPengampu);
    } else {
      daftarPengampuFiltered.assignAll(
        _semuaPengampu.where((p) => p.namaPengampu.toLowerCase().contains(query))
      );
    }
  }

  Future<void> loadDataPengampu() async {
    if (selectedFase.value == null) return;
    isLoading.value = true;
    try {
       final namaTahunAjaranLama = (await homeController.getTahunAjaranTerakhir()); // "2025/2026"
      final idTahunAjaran = namaTahunAjaranLama.replaceAll("/", "-"); // "2025-2026"
      final namaDokumenFase = "Fase ${selectedFase.value}";

      final tempatSnapshot = await firestore.collectionGroup('tempat')
          .where('fase', isEqualTo: namaDokumenFase)
          .where('tahunajaran', isEqualTo: idTahunAjaran) // <-- Cari dengan format '-'
          .get();

      if (tempatSnapshot.docs.isNotEmpty) {
        final List<Future<PengampuInfo?>> futures = tempatSnapshot.docs
            .map((doc) => _createPengampuInfoFromDoc(doc, namaDokumenFase))
            .toList();

        final List<PengampuInfo> hasilAkhir = (await Future.wait(futures))
            .whereType<PengampuInfo>() // Cara lebih aman untuk memfilter null
            .toList();

        _semuaPengampu.assignAll(hasilAkhir);
        _filterData();
      } else {
        _semuaPengampu.clear();
        daftarPengampuFiltered.clear();
      }
    } catch (e) {
      if (kDebugMode) print("Error saat loadDataPengampu: $e");
      _semuaPengampu.clear();
      daftarPengampuFiltered.clear();
      Get.snackbar("Error", "Gagal memuat data. Mungkin memerlukan index Firestore. Cek Debug Console.");
    } finally {
      isLoading.value = false;
    }
  }

  Future<PengampuInfo?> _createPengampuInfoFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> tempatDoc,
    String namaDokumenFase,
  ) async {
    String? idPengampu; // Deklarasikan di luar try-catch
    try {
      final idTahunAjaran = homeController.idTahunAjaran.value!;
      final semesterAktif = homeController.semesterAktifId.value;
      
      final dataTempat = tempatDoc.data();
      final String namaPengampu = dataTempat['namapengampu'];
      idPengampu = dataTempat['idpengampu'];
      final String namaTempat = tempatDoc.id;

      Future<QuerySnapshot<Map<String, dynamic>>> siswaSnapshotFuture = firestore
          .collection('Sekolah').doc(homeController.idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelompokmengaji').doc(namaDokumenFase)
          .collection('pengampu').doc(idPengampu)
          .collection('tempat').doc(namaTempat)
          .collection('semester').doc(semesterAktif)
          .collection('daftarsiswa').get();

      Future<DocumentSnapshot<Map<String, dynamic>>> pegawaiDocFuture = firestore
          .collection('Sekolah').doc(homeController.idSekolah)
          .collection('pegawai').doc(idPengampu).get();
      
      final results = await Future.wait([pegawaiDocFuture, siswaSnapshotFuture]);
      final pegawaiDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final siswaSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;

      final profileImageUrl = pegawaiDoc.exists ? pegawaiDoc.data()!['profileImageUrl'] as String? : null;
      final jumlahSiswa = siswaSnapshot.docs.length;
      final jumlahSiapUjian = siswaSnapshot.docs.where((doc) => doc.data()['status_ujian'] == 'siap_ujian').length;
      
      return PengampuInfo(
        fase: namaDokumenFase,
        namaPengampu: namaPengampu,
        idPengampu: idPengampu as String,
        namaTempat: namaTempat,
        profileImageUrl: profileImageUrl,
        jumlahSiswa: jumlahSiswa,
        jumlahSiapUjian: jumlahSiapUjian,
      );
    } catch (e) {
      if (kDebugMode) print("Error memproses detail untuk pengampu ${idPengampu ?? 'UNKNOWN'}: $e");
      return null;
    }
  }

  // [FUNGSI BARU] Untuk memperbaiki data shortcut siswa per fase.
  Future<void> migrasiDataShortcutSiswaPerFase(String namaFase) async {
    Get.dialog(
      const AlertDialog(
        title: Text("Migrasi Data..."),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Proses ini bisa memakan waktu beberapa saat. Mohon jangan tutup aplikasi."),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final idTahunAjaran = homeController.idTahunAjaran.value!;
      final semesterAktif = homeController.semesterAktifId.value;
      int siswaDiperbaiki = 0;

      // 1. Ambil semua kelompok di fase ini untuk mendapatkan idpengampu yang benar
      final tempatSnapshot = await firestore.collectionGroup('tempat')
          .where('fase', isEqualTo: namaFase)
          .where('tahunajaran', isEqualTo: idTahunAjaran)
          .get();

      if (tempatSnapshot.docs.isEmpty) {
        Get.back();
        Get.snackbar("Info", "Tidak ada kelompok yang ditemukan di $namaFase untuk dimigrasi.");
        return;
      }
      
      final WriteBatch batch = firestore.batch();

      // 2. Lakukan iterasi untuk setiap kelompok
      for (var tempatDoc in tempatSnapshot.docs) {
        final dataTempat = tempatDoc.data();
        final String idPengampu = dataTempat['idpengampu'];
        
        // 3. Ambil semua siswa di dalam kelompok tersebut
        final siswaSnapshot = await tempatDoc.reference
            .collection('semester').doc(semesterAktif)
            .collection('daftarsiswa').get();

        if (siswaSnapshot.docs.isEmpty) continue; // Lanjut ke kelompok berikutnya jika kosong

        // 4. Untuk setiap siswa, siapkan operasi update pada "shortcut"-nya
        for (var siswaDoc in siswaSnapshot.docs) {
          final nisn = siswaDoc.id;
          final refShortcut = firestore
              .collection('Sekolah').doc(homeController.idSekolah)
              .collection('siswa').doc(nisn)
              .collection('tahunajarankelompok').doc(idTahunAjaran)
              .collection('semester').doc(semesterAktif)
              .collection('kelompokmengaji').doc(namaFase);

          // Gunakan .update() untuk menambahkan field baru tanpa menimpa yang lama
          batch.update(refShortcut, {'idpengampu': idPengampu});
          siswaDiperbaiki++;
        }
      }

      // 5. Jalankan semua operasi update sekaligus
      await batch.commit();
      
      Get.back(); // Tutup dialog loading
      Get.snackbar("Berhasil", "$siswaDiperbaiki data siswa di $namaFase telah berhasil diperbaiki.");

    } catch (e) {
      Get.back();
      Get.snackbar("Error Migrasi", "Terjadi kesalahan: ${e.toString()}");
    }
  }
}
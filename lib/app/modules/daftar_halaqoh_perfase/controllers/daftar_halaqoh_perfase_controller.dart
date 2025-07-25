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

  // Future<void> loadDataPengampu() async {
  //   if (selectedFase.value == null) return;
  //   isLoading.value = true;
  //   try {
  //     final namaTahunAjaran = (await homeController.getTahunAjaranTerakhir());
  //     final namaDokumenFase = "Fase ${selectedFase.value}";

  //     // --- DEBUGGING DIMULAI ---
  //     print("================ INVESTIGASI DIMULAI ================");
  //     print("Mencari dokumen 'tempat' dengan kriteria:");
  //     print("1. Field 'fase' HARUS SAMA PERSIS DENGAN: '$namaDokumenFase'");
  //     print("2. Field 'tahunajaran' HARUS SAMA PERSIS DENGAN: '$namaTahunAjaran'");
  //     print("----------------------------------------------------");
  //     // --- DEBUGGING SELESAI ---

  //     final tempatSnapshot = await firestore.collectionGroup('tempat')
  //         .where('fase', isEqualTo: namaDokumenFase)
  //         .where('tahunajaran', isEqualTo: namaTahunAjaran)
  //         .get();
      
  //     print("HASIL: Query collectionGroup('tempat') menemukan ${tempatSnapshot.docs.length} dokumen.");
  //     print("================ INVESTIGASI SELESAI ================\n");

  //     if (tempatSnapshot.docs.isNotEmpty) {
  //       // ... sisa fungsi tidak berubah
  //     } else {
  //       _semuaPengampu.clear();
  //       daftarPengampuFiltered.clear();
  //     }
  //   } catch (e) {
  //     if (kDebugMode) print("Error saat loadDataPengampu: $e");
  //     _semuaPengampu.clear();
  //     daftarPengampuFiltered.clear();
  //     Get.snackbar("Error", "Gagal memuat data. Mungkin memerlukan index Firestore. Cek Debug Console.");
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

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
}
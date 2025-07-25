// lib/app/modules/pemberian_guru_mapel/controllers/pemberian_guru_mapel_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../modules/home/controllers/home_controller.dart';

class PemberianGuruMapelController extends GetxController {
  // --- DEPENDENSI ---
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();
  final String idSekolah = '20404148';
  late String idTahunAjaran;
  
  // --- STATE MANAGEMENT ---
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMapel = false.obs;
  final RxBool isDialogLoading = false.obs;
  
  final RxList<String> daftarKelas = <String>[].obs;
  final RxList<Map<String, String>> daftarGuru = <Map<String, String>>[].obs;
  
  // Ini akan menjadi "checklist" mata pelajaran wajib berdasarkan fase
  final RxList<String> daftarMapelWajib = <String>[].obs;
  
  final Rxn<String> kelasTerpilih = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  /// Mengambil data awal yang tidak bergantung pada pilihan kelas,
  /// yaitu daftar kelas dan daftar semua guru yang bisa mengajar.
  Future<void> _initializeData() async {
    try {
      isLoading.value = true;
      idTahunAjaran = homeC.idTahunAjaran.value!;
      
      // Jalankan pengambilan data secara bersamaan untuk efisiensi
      await Future.wait([
        _fetchDaftarKelas(),
        _fetchDaftarGuru(),
      ]);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data awal: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Aksi yang dijalankan saat pengguna memilih kelas.
  /// Ini menjadi fungsi utama untuk mengambil kurikulum yang relevan.
  Future<void> gantiKelasTerpilih(String namaKelas) async {
    // Hindari reload jika kelas yang sama dipilih lagi
    if (kelasTerpilih.value == namaKelas) return;

    kelasTerpilih.value = namaKelas;
    isLoadingMapel.value = true;
    daftarMapelWajib.clear(); // Kosongkan checklist lama

    try {
      // 1. Tentukan Fase berdasarkan nama kelas
      final String kelasAngka = namaKelas.substring(0, 1);
      final String idFase = (kelasAngka == '1' || kelasAngka == '2') ? "fase_a"
                          : (kelasAngka == '3' || kelasAngka == '4') ? "fase_b"
                          : "fase_c";
      
      // 2. Ambil kurikulum dari Firestore di level root
      final kurikulumDoc = await firestore.collection('konfigurasi_kurikulum').doc(idFase).get();
      if (!kurikulumDoc.exists || kurikulumDoc.data()?['matapelajaran'] == null) {
        throw Exception("Konfigurasi kurikulum untuk $idFase tidak ditemukan.");
      }
      
      final List<String> mapelDariDB = List<String>.from(kurikulumDoc.data()!['matapelajaran']);
      daftarMapelWajib.assignAll(mapelDariDB);

    } catch (e) {
      Get.snackbar("Gagal Memuat Kurikulum", e.toString().replaceAll('Exception: ', ''));
    } finally {
      isLoadingMapel.value = false;
    }
  }

  /// Mengambil daftar semua kelas aktif dari HomeController.
  // Future<void> _fetchDaftarKelas() async {
  //   final kelas = await homeC.getDataKelasMapel();
  //   daftarKelas.assignAll(kelas);
  // }
  Future<void> _fetchDaftarKelas() async {
    // Memastikan kita mengambil dari sumber yang benar (kelastahunajaran)
    final snapshot = await firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelastahunajaran').get();
    daftarKelas.assignAll(snapshot.docs.map((doc) => doc.id).toList()..sort());
  }

  /// Mengambil daftar semua pegawai yang bisa menjadi guru mapel.
  Future<void> _fetchDaftarGuru() async {
    final snapshot = await firestore
        .collection('Sekolah').doc(idSekolah).collection('pegawai')
        .where('role', whereIn: ['Pengampu', 'Guru Kelas']).get();
    
    final guruList = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'uid': doc.id,
        'nama': data['alias'] as String? ?? 'Tanpa Nama',
        'role': data['role'] as String? ?? 'Tanpa Role',
      };
    }).toList();
    daftarGuru.assignAll(guruList);
  }
  
  /// Menyediakan stream data real-time untuk mapel yang sudah ditugaskan
  /// di kelas yang sedang dipilih.
  Stream<QuerySnapshot<Map<String, dynamic>>> getAssignedMapelStream() {
    if (kelasTerpilih.value == null) return const Stream.empty();
    
    return firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        // .collection('kelasmapel').doc(kelasTerpilih.value!)
        .collection('penugasan').doc(kelasTerpilih.value!)
        .collection('matapelajaran')
        .snapshots();
  }

  /// [FUNGSI BARU] Menyimpan konfigurasi bobot nilai.
  // Future<void> simpanBobotNilai(Map<String, dynamic> bobotBaru) async {
  //   if (kelasTerpilih.value == null) { Get.snackbar("Error", "Kelas belum dipilih."); return; }

  //   int totalBobot = bobotBaru.values.reduce((a, b) => a + b);
  //   if (totalBobot != 100) {
  //     Get.snackbar("Peringatan", "Total bobot harus 100%, saat ini totalnya $totalBobot%.");
  //     return;
  //   }

  //   final String namaMapel = bobotBaru['namaMapel'] as String; // Kita akan selipkan nama mapel ke map

  //   isDialogLoading.value = true;
  //   try {
  //     final ref = firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran')
  //         .doc(idTahunAjaran).collection('penugasan').doc(kelasTerpilih.value!)
  //         .collection('matapelajaran').doc(namaMapel);

  //     await ref.set({'bobot_nilai': bobotBaru}, SetOptions(merge: true));
  //     Get.back();
  //     Get.snackbar("Berhasil", "Bobot nilai untuk $namaMapel telah disimpan.");
  //   } catch (e) { Get.snackbar("Error", "Gagal menyimpan bobot: $e"); }
  //   finally { isDialogLoading.value = false; }
  // }


  Future<void> assignGuruToMapel(String idGuru, String namaGuru, String namaMapel) async {
    if (kelasTerpilih.value == null) {
      Get.snackbar("Gagal", "Kelas belum dipilih.");
      return;
    }
    final String namaKelas = kelasTerpilih.value!;
    
    // Ambil data global dari sumber yang sama untuk memastikan konsistensi
    final String idTahunAjaranDariHome = homeC.idTahunAjaran.value!;
    final String semesterAktif = homeC.semesterAktifId.value;

    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

    try {
      WriteBatch batch = firestore.batch();
      
      // Path 1: Ke koleksi 'penugasan' (master data untuk 1 tahun ajaran)
      final penugasanRef = firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaranDariHome)
          .collection('penugasan').doc(namaKelas)
          .collection('matapelajaran').doc(namaMapel);

      // --- PERBAIKAN UTAMA DI SINI ---
      // Path 1.5: Path ke DOKUMEN KELAS ("rumah") di dalam koleksi 'kelasnya'
      final pegawaiKelasRef = firestore.collection('Sekolah').doc(idSekolah)
          .collection('pegawai').doc(idGuru)
          .collection('tahunajaran').doc(idTahunAjaranDariHome)
          .collection('semester').doc(semesterAktif)
          .collection('kelasnya').doc(namaKelas);

      // Path 2: Path ke DOKUMEN MAPEL ("kamar") di dalam subkoleksi
      final pegawaiMapelRef = pegawaiKelasRef.collection('matapelajaran').doc(namaMapel);
      // ------------------------------------

      final docSnap = await penugasanRef.get();
      if (docSnap.exists) {
        throw Exception('Mata pelajaran ini sudah memiliki guru.');
      }

      final dataToSave = {
        'namamatapelajaran': namaMapel, 'guru': namaGuru, 'idGuru': idGuru,
        'idKelas': namaKelas, 'idTahunAjaran': idTahunAjaranDariHome,
        'diinputPada': FieldValue.serverTimestamp(), 'semester': semesterAktif,
      };
      
      // --- OPERASI BARU YANG KRUSIAL ---
      // Buat atau update "rumahnya" (dokumen kelas) terlebih dahulu.
      // SetOptions(merge: true) penting agar tidak menghapus subkoleksi 
      // matapelajaran lain yang mungkin sudah ada jika guru ini mengajar
      // lebih dari satu mapel di kelas yang sama.
      batch.set(pegawaiKelasRef, {'namaKelas': namaKelas}, SetOptions(merge: true));
      // ------------------------------------

      // Tulis ke kedua lokasi
      batch.set(penugasanRef, dataToSave);
      batch.set(pegawaiMapelRef, dataToSave);
      
      await batch.commit();
      
      Get.back();
      Get.snackbar('Berhasil', '$namaMapel telah diberikan kepada $namaGuru');
    } catch (e) {
      Get.back();
      Get.snackbar('Gagal', e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> removeGuruFromMapel(String namaMapel) async {
       if (kelasTerpilih.value == null) {
      Get.snackbar("Gagal", "Kelas belum dipilih.");
      return;
    }
    final String namaKelas = kelasTerpilih.value!;
    final String idTahunAjaranDariHome = homeC.idTahunAjaran.value!;
    final String semesterAktif = homeC.semesterAktifId.value;

    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      final penugasanRef = firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaranDariHome).collection('penugasan').doc(namaKelas).collection('matapelajaran').doc(namaMapel);
      final doc = await penugasanRef.get();
      if (!doc.exists) { Get.back(); Get.snackbar("Info", "Data sudah tidak ditemukan."); return; }
      
      final String? idGuru = doc.data()?['idGuru'] as String?;
      if (idGuru == null) { throw Exception('ID Guru tidak ditemukan.'); }

      // Hapus hanya dokumen mapelnya saja. Dokumen induk 'kelasnya' biarkan ada.
      final pegawaiMapelRef = firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idGuru)
          .collection('tahunajaran').doc(idTahunAjaranDariHome).collection('semester').doc(semesterAktif)
          .collection('kelasnya').doc(namaKelas).collection('matapelajaran').doc(namaMapel);

      WriteBatch batch = firestore.batch();
      batch.delete(penugasanRef);
      batch.delete(pegawaiMapelRef);
      await batch.commit();

      Get.back();
      Get.snackbar('Berhasil', 'Guru untuk $namaMapel telah dihapus.');
    } catch (e) { Get.back(); Get.snackbar('Gagal', e.toString()); }
  }
}
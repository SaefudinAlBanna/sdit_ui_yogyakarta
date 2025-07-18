// lib/app/modules/daftar_kelas/controllers/daftar_kelas_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

// Kita butuh akses ke HomeController untuk mengambil data yang sudah ada
import '../../../modules/home/controllers/home_controller.dart'; 

class DaftarKelasController extends GetxController {
  // Hapus 'var data = Get.arguments;' karena sudah tidak digunakan lagi.

  // --- DEPENDENSI ---
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>(); // Akses HomeController

  // --- STATE MANAGEMENT (Data yang akan ditampilkan di UI) ---
  
  // State untuk memantau proses loading data
  final RxBool isLoadingKelas = true.obs; 
  final RxBool isLoadingMapel = false.obs;

  // Daftar kelas yang diajar oleh guru (diambil dari HomeController)
  final RxList<String> daftarKelasDiajar = <String>[].obs;
  
  // Menyimpan nama kelas yang sedang dipilih oleh pengguna
  final Rxn<String> kelasTerpilih = Rxn<String>();

  // Daftar mata pelajaran untuk kelas yang dipilih
  final RxList<Map<String, dynamic>> daftarMapel = <Map<String, dynamic>>[].obs;


  @override
  void onInit() {
    super.onInit();
    // Saat controller pertama kali dijalankan, langsung ambil daftar kelas
    fetchKelasYangDiajar();
  }

  // --- FUNGSI-FUNGSI LOGIKA ---

  /// 1. Mengambil daftar kelas yang diajar guru.
  Future<void> fetchKelasYangDiajar() async {
    try {
      isLoadingKelas.value = true;
      // Memanggil fungsi yang sudah ada di HomeController, lebih efisien!
      final kelas = await homeC.getDataKelasYangDiajar();
      
      daftarKelasDiajar.assignAll(kelas);

      // Jika ada kelas, otomatis pilih kelas pertama dan tampilkan mapelnya
      if (daftarKelasDiajar.isNotEmpty) {
        gantiKelasTerpilih(daftarKelasDiajar.first);
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat daftar kelas: $e");
    } finally {
      isLoadingKelas.value = false;
    }
  }

  /// 2. Aksi yang dijalankan saat pengguna memilih kelas lain.
  void gantiKelasTerpilih(String namaKelas) {
    // Set kelas terpilih
    print("Kelas diganti ke: $namaKelas");
    kelasTerpilih.value = namaKelas;
    // Ambil data mapel untuk kelas yang baru dipilih
    fetchDataMapel(namaKelas);
  }

  /// 3. Mengambil daftar mata pelajaran dari Firestore berdasarkan kelas yang dipilih.
  Future<void> fetchDataMapel(String namaKelas) async {
    try {
      isLoadingMapel.value = true;
      daftarMapel.clear(); // Kosongkan daftar mapel lama

      String idTahunAjaran = homeC.idTahunAjaran.value!;
      String idUser = auth.currentUser!.uid;
      String idSekolah = homeC.idSekolah;

      final snapshot = await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('pegawai')
          .doc(idUser)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelasnya')
          .doc(namaKelas) // Gunakan namaKelas dari parameter
          .collection('matapelajaran')
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Ubah QueryDocumentSnapshot menjadi List<Map> agar lebih mudah dikelola
        final listMapel = snapshot.docs.map((doc) => doc.data()).toList();
        daftarMapel.assignAll(listMapel);
      }

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat mata pelajaran: $e");
    } finally {
      isLoadingMapel.value = false;
    }
  }
}
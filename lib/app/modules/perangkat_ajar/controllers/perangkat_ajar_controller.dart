// app/controller/perangkat_ajar_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

// Import models
import '../../../models/atp_model.dart';
import '../../../models/modul_ajar_model.dart';

// Import HomeController untuk mendapatkan info user/sekolah
import '../../home/controllers/home_controller.dart';

class PerangkatAjarController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final HomeController homeC;
  var uuid = Uuid();

  // --- STATE MANAGEMENT ---
  final RxList<AtpModel> daftarAtp = <AtpModel>[].obs;
  final RxList<ModulAjarModel> daftarModulAjar = <ModulAjarModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString tahunAjaranAktif = ''.obs;
  final RxList<String> daftarTahunAjaranLama = <String>[].obs;

  final RxString tahunAjaranFilter = ''.obs;
  
  // Data user yang tidak butuh loading
  late final String idSekolah;
  late final String idUser;
  // 'namaUser' tidak lagi menjadi properti class, akan diambil on-demand.

  @override
  void onInit() {
    super.onInit();
    
    if (Get.isRegistered<HomeController>()) {
      homeC = Get.find<HomeController>();
      idSekolah = homeC.idSekolah;
      idUser = homeC.idUser;
    } else {
      idSekolah = "20404148"; 
      idUser = "";
      showErrorSnackbar("Error Kritis", "Sesi pengguna tidak ditemukan.");
      isLoading.value = false;
      return;
    }

    // Dengarkan perubahan tahun ajaran dari HomeController
    ever(homeC.idTahunAjaran, (String? idTahun) {
      if (idTahun != null && idTahun.isNotEmpty) {
        tahunAjaranAktif.value = idTahun;
        tahunAjaranFilter.value = idTahun;
        fetchAllData();
      }
    });

    // Panggil sekali di awal untuk handle kasus jika data sudah ada
    // Blok ini akan dijalankan jika pengguna masuk ke halaman ini setelah HomeController selesai loading.
    if (homeC.idTahunAjaran.value != null && homeC.idTahunAjaran.value!.isNotEmpty) {
      String idTahunAwal = homeC.idTahunAjaran.value!;
      tahunAjaranAktif.value = idTahunAwal;
      // --- INILAH PERBAIKAN KUNCINYA ---
      // Pastikan tahunAjaranFilter juga diisi di sini.
      tahunAjaranFilter.value = idTahunAwal;
      // --- AKHIR PERBAIKAN ---
      fetchAllData();
    } else {
      // Jika tahun ajaran belum siap saat controller ini dibuat,
      // kita set isLoading ke false agar tidak loading terus.
      // Listener 'ever' di atas akan menangani pemanggilan fetchAllData saat datanya sudah siap.
      isLoading.value = false;
    }
  }

  Future<void> fetchAllData() async {
    isLoading.value = true;
    await Future.wait([
      fetchAtpList(tahunAjaranFilter.value),
      fetchModulAjarList(tahunAjaranFilter.value),
      fetchTahunAjaranLama(),
    ]);
    isLoading.value = false;
  }

  // --- FUNGSI BARU: Untuk mengubah filter ---
  void gantiTahunAjaranFilter(String tahunBaruId) {
    if (tahunAjaranFilter.value != tahunBaruId) {
      tahunAjaranFilter.value = tahunBaruId;
      // Panggil lagi fetch data untuk ATP dan Modul Ajar dengan tahun yang baru
      isLoading.value = true;
      Future.wait([
        fetchAtpList(tahunBaruId),
        fetchModulAjarList(tahunBaruId),
      ]).then((_) {
        isLoading.value = false;
      });
    }
  }

  void showErrorSnackbar(String title, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
      Get.snackbar(title, message, backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    });
  }

  /// Mengambil daftar ATP dari tahun ajaran spesifik.
  Future<List<AtpModel>> getAtpListFromTahun(String tahunAjaranId) async {
    try {
      final snapshot = await _firestore
          .collection('Sekolah').doc(idSekolah).collection('atp')
          .where('idPenyusun', isEqualTo: idUser)
          .where('idTahunAjaran', isEqualTo: tahunAjaranId)
          .get();
      return snapshot.docs.map((doc) => AtpModel.fromJson(doc.data())).toList();
    } catch (e) {
      showErrorSnackbar('Error', 'Gagal mengambil data ATP dari tahun $tahunAjaranId');
      return []; // Kembalikan list kosong jika error
    }
  }

  /// Mengambil daftar Modul Ajar dari tahun ajaran spesifik.
  Future<List<ModulAjarModel>> getModulAjarListFromTahun(String tahunAjaranId) async {
    try {
      final snapshot = await _firestore
          .collection('Sekolah').doc(idSekolah).collection('modulAjar')
          .where('idPenyusun', isEqualTo: idUser)
          .where('idTahunAjaran', isEqualTo: tahunAjaranId)
          .get();
      return snapshot.docs.map((doc) => ModulAjarModel.fromJson(doc.data())).toList();
    } catch (e) {
      showErrorSnackbar('Error', 'Gagal mengambil data Modul Ajar dari tahun $tahunAjaranId');
      return [];
    }
  }

  // ==========================================================
  // --- FUNGSI-FUNGSI FETCH DATA ---
  // ==========================================================

  Future<void> fetchTahunAjaranLama() async {
    try {
      if (tahunAjaranAktif.value.isEmpty) return;
      final snapshot = await _firestore
          .collection('Sekolah').doc(idSekolah).collection('tahunajaran')
          .where('idtahunajaran', isNotEqualTo: tahunAjaranAktif.value)
          .orderBy('idtahunajaran', descending: true)
          .get();
       daftarTahunAjaranLama.value = snapshot.docs
          .map((doc) => doc.data()['idtahunajaran'] as String)
          .toList();
    } catch (e) {
      showErrorSnackbar('Error', 'Gagal mengambil daftar tahun ajaran lama: ${e.toString()}');
    }
  }

  Future<void> fetchAtpList(String tahunAjaran) async {

    // --- TAMBAHKAN PRINT DEBUG DI SINI ---
    print("========================================");
    print("DEBUG: Menjalankan query dengan parameter:");
    print("--> idUser (Penyusun): $idUser");
    print("--> idTahunAjaran: $tahunAjaran");
    print("========================================");
    // --- AKHIR PRINT DEBUG ---

    try {
      final snapshot = await _firestore
          .collection('Sekolah').doc(idSekolah).collection('atp')
          .where('idPenyusun', isEqualTo: idUser)
          .where('idTahunAjaran', isEqualTo: tahunAjaran)
          .orderBy('lastModified', descending: true)
          .get();
      daftarAtp.value = snapshot.docs.map((doc) => AtpModel.fromJson(doc.data())).toList();
    } catch (e) {
      showErrorSnackbar('Error', 'Gagal mengambil data ATP: ${e.toString()}');
    }
  }
  
  Future<void> fetchModulAjarList(String tahunAjaran) async {
    try {
      final snapshot = await _firestore
          .collection('Sekolah').doc(idSekolah).collection('modulAjar')
          .where('idPenyusun', isEqualTo: idUser)
          .where('idTahunAjaran', isEqualTo: tahunAjaran)
          .orderBy('lastModified', descending: true)
          .get();
      daftarModulAjar.value = snapshot.docs.map((doc) => ModulAjarModel.fromJson(doc.data())).toList();
    } catch (e) {
      showErrorSnackbar('Error', 'Gagal mengambil data Modul Ajar: ${e.toString()}');
    }
  }

  // ==========================================================
  // --- FUNGSI-FUNGSI CRUD (CREATE, UPDATE, DELETE) ---
  // ==========================================================

  Future<void> createAtp(AtpModel atp) async {
    try {
      // --- PERBAIKAN DI SINI ---
      final userSnapshot = await homeC.userStream().first;
      final namaPenyusun = userSnapshot.data()?['nama'] ?? 'Guru';
      // --- AKHIR PERBAIKAN ---

      atp.idAtp = uuid.v4();
      atp.createdAt = Timestamp.now();
      atp.lastModified = Timestamp.now();
      atp.namaPenyusun = namaPenyusun; 
      
      await _firestore.collection('Sekolah').doc(idSekolah).collection('atp').doc(atp.idAtp).set(atp.toJson());
      
      daftarAtp.insert(0, atp);
      Get.back();
      Get.snackbar('Berhasil', 'ATP baru berhasil dibuat.');
    } catch (e) {
      showErrorSnackbar('Error', 'Gagal membuat ATP: ${e.toString()}');
    }
  }

  Future<void> updateAtp(AtpModel atp) async {
    try {
      atp.lastModified = Timestamp.now();
      await _firestore.collection('Sekolah').doc(idSekolah).collection('atp').doc(atp.idAtp).update(atp.toJson());
      int index = daftarAtp.indexWhere((item) => item.idAtp == atp.idAtp);
      if (index != -1) daftarAtp[index] = atp;
      Get.back();
      Get.snackbar('Berhasil', 'ATP berhasil diperbarui.');
    } catch (e) {
      showErrorSnackbar('Error', 'Gagal memperbarui ATP: ${e.toString()}');
    }
  }

  Future<void> deleteAtp(String idAtp) async {
    try {
      await _firestore.collection('Sekolah').doc(idSekolah).collection('atp').doc(idAtp).delete();
      daftarAtp.removeWhere((item) => item.idAtp == idAtp);
      Get.snackbar('Berhasil', 'ATP berhasil dihapus.');
    } catch (e) {
      showErrorSnackbar('Error', 'Gagal menghapus ATP: ${e.toString()}');
    }
  }

  Future<void> createModulAjar(ModulAjarModel modul) async {
    try {
      // --- PERBAIKAN DI SINI ---
      final userSnapshot = await homeC.userStream().first;
      final namaPenyusun = userSnapshot.data()?['nama'] ?? 'Guru';
      // --- AKHIR PERBAIKAN ---

      modul.idModul = uuid.v4();
      modul.createdAt = Timestamp.now();
      modul.lastModified = Timestamp.now();
      modul.namaPenyusun = namaPenyusun;
      
      await _firestore.collection('Sekolah').doc(idSekolah).collection('modulAjar').doc(modul.idModul).set(modul.toJson());
      
      daftarModulAjar.insert(0, modul);
      Get.back();
      Get.snackbar('Berhasil', 'Modul Ajar baru berhasil dibuat.');
    } catch (e) {
      showErrorSnackbar('Error', 'Gagal membuat Modul Ajar: ${e.toString()}');
    }
  }

  Future<void> updateModulAjar(ModulAjarModel modul) async {
    try {
      modul.lastModified = Timestamp.now();
      await _firestore.collection('Sekolah').doc(idSekolah).collection('modulAjar').doc(modul.idModul).update(modul.toJson());
      int index = daftarModulAjar.indexWhere((item) => item.idModul == modul.idModul);
      if (index != -1) daftarModulAjar[index] = modul;
      Get.back();
      Get.snackbar('Berhasil', 'Modul Ajar berhasil diperbarui.');
    } catch (e) {
      showErrorSnackbar('Error', 'Gagal memperbarui Modul Ajar: ${e.toString()}');
    }
  }

  Future<void> deleteModulAjar(String idModul) async {
    try {
      await _firestore.collection('Sekolah').doc(idSekolah).collection('modulAjar').doc(idModul).delete();
      daftarModulAjar.removeWhere((item) => item.idModul == idModul);
      Get.snackbar('Berhasil', 'Modul Ajar berhasil dihapus.');
    } catch (e) {
      showErrorSnackbar('Error', 'Gagal menghapus Modul Ajar: ${e.toString()}');
    }
  }

  Future<void> duplikasiAtp(AtpModel atpLama, String tahunAjaranBaru) async {
    // isLoading.value = true; // Bisa ditambahkan jika ingin ada loading spesifik
    try {
       AtpModel atpBaru = atpLama.copyWith(
         idAtp: uuid.v4(),
         idTahunAjaran: tahunAjaranBaru,
       );
       await _firestore.collection('Sekolah').doc(idSekolah).collection('atp').doc(atpBaru.idAtp).set(atpBaru.toJson());
       Get.snackbar('Berhasil', 'ATP berhasil diduplikasi ke tahun ajaran $tahunAjaranBaru');
    } catch (e) {
      showErrorSnackbar('Error', 'Gagal menduplikasi ATP: ${e.toString()}');
    } finally {
      // isLoading.value = false;
    }
  }

  Future<void> duplikasiModulAjar(ModulAjarModel modulLama, String tahunAjaranBaru) async {
    try {
       // Gunakan copyWith dari model ModulAjar
       ModulAjarModel modulBaru = modulLama.copyWith(
         idModul: uuid.v4(), // Generate ID baru yang unik
         idTahunAjaran: tahunAjaranBaru,
       );
       
       await _firestore
          .collection('Sekolah').doc(idSekolah).collection('modulAjar')
          .doc(modulBaru.idModul)
          .set(modulBaru.toJson());
          
       // Tidak perlu Get.snackbar di sini karena akan di-handle oleh dialog
       
    } catch (e) {
      // Melempar error agar bisa ditangkap oleh try-catch di dialog
      throw Exception('Gagal menduplikasi Modul Ajar: ${e.toString()}');
    }
  }
}
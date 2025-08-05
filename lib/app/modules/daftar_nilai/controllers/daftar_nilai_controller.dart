// lib/app/modules/daftar_nilai/controllers/daftar_nilai_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/nilai_halaqoh_umi.dart'; // <-- Import model baru
import '../../home/controllers/home_controller.dart';
import 'package:flutter/material.dart';

class DaftarNilaiController extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeController = Get.find<HomeController>();
  final String idSekolah = '20404148'; // Sesuaikan ID Sekolah Anda
  
  // Ambil data siswa dari argumen halaman sebelumnya
  // final Map<String, dynamic> dataSiswa = Get.arguments;
  final Rx<Map<String, dynamic>> dataSiswa = Rx<Map<String, dynamic>>({});

  // --- STATE REAKTIF (mengikuti pola Al-Husna) ---
  var isLoading = true.obs;
  var isDialogLoading = false.obs; 
  var daftarNilai = <NilaiHalaqohUmi>[].obs; // List berisi model, bukan data mentah
  final RxString lokasiTampilan = 'Memuat lokasi...'.obs;

   // --- CONTROLLER BARU UNTUK DIALOG EDIT ---
  late TextEditingController suratEditC;
  late TextEditingController ayatEditC;
  late TextEditingController capaianEditC;
  late TextEditingController nilaiEditC;
  late TextEditingController catatanEditC;
  // ... tambahkan controller lain jika perlu diedit
  

  bool get canEditOrDelete {
    // Pengampu yang bersangkutan, Koordinator, atau Admin boleh edit/hapus
    final user = homeController.auth.currentUser;
    if (user == null) return false;
    return user.uid == dataSiswa.value['idpengampu'] || homeController.canEditOrDeleteHalaqoh;
  }

  @override
  void onInit() {
    super.onInit();
    // Inisialisasi semua text controller
    suratEditC = TextEditingController();
    ayatEditC = TextEditingController();
    capaianEditC = TextEditingController();
    nilaiEditC = TextEditingController();
    catatanEditC = TextEditingController();

    // Ambil argumen dari halaman sebelumnya
    final Map<String, dynamic>? args = Get.arguments as Map<String, dynamic>?;

    if (args != null) {
      dataSiswa.value = args;
      // Panggil kedua fungsi pengambilan data
      fetchDataNilai();
      // _fetchLokasiTampilan(); // <-- [BARU] Panggil fungsi lokasi di sini
    } else {
      // Tangani jika tidak ada argumen (seharusnya tidak terjadi)
      Get.snackbar("Error", "Gagal memuat data siswa.");
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    // Selalu dispose controller
    suratEditC.dispose(); ayatEditC.dispose();
    capaianEditC.dispose(); nilaiEditC.dispose();
    catatanEditC.dispose();
    super.onClose();
  }

  Future<void> updateCatatanPengampu(NilaiHalaqohUmi nilai) async {
    if (catatanEditC.text.trim() == nilai.keteranganPengampu) { Get.back(); return; }
    isDialogLoading.value = true;
    try {
      final docRef = _getNilaiDocRef(nilai.id);
      
      final uidPengedit = homeController.auth.currentUser!.uid;
      final docPengedit = await firestore.collection('Sekolah').doc(homeController.idSekolah).collection('pegawai').doc(uidPengedit).get();
      final aliasPengedit = docPengedit.data()?['alias'] ?? 'User';
      final rolePengedit = homeController.userRole.value ?? 'Role';
      final namaTampilanPengedit = "$aliasPengedit ($rolePengedit)";

      await docRef.update({
        'keteranganpengampu': catatanEditC.text.trim(),
        'terakhir_diubah': FieldValue.serverTimestamp(),
        'diubah_oleh_nama': namaTampilanPengedit,
        'diubah_oleh_uid': uidPengedit,
      });

      Get.back();
      Get.snackbar("Berhasil", "Catatan pengampu berhasil diperbarui.");
      fetchDataNilai();

    } catch (e) {
      Get.snackbar("Error", "Gagal memperbarui catatan: $e");
    } finally {
      isDialogLoading.value = false;
    }
  }

  //========================================================================
  // --- FUNGSI BARU UNTUK HAK AKSES, EDIT, DAN DELETE ---
  //========================================================================

  String _getGrade(int score) {
    if (score >= 90) return 'A';
    if (score >= 85) return 'B+';
    if (score >= 80) return 'B';
    if (score >= 75) return 'B-';
    if (score >= 70) return 'C+';
    if (score >= 65) return 'C';
    if (score >= 60) return 'C-';
    return 'D';
  }

  /// [FUNGSI BARU] Menghapus dokumen nilai.
  Future<void> deleteNilai(NilaiHalaqohUmi nilai) async {
    Get.defaultDialog(
      title: "Konfirmasi Hapus",
      middleText: "Anda yakin ingin menghapus nilai ini?",
      textConfirm: "Ya, Hapus", textCancel: "Batal",
      confirmTextColor: Colors.white, buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        isDialogLoading.value = true;
        try {
          final docNilaiRef = _getNilaiDocRef(nilai.id);
          final siswaIndukRef = _getSiswaIndukRef();
          final koleksiNilaiRef = siswaIndukRef.collection('nilai');

          await docNilaiRef.delete();

          final sisaNilaiSnapshot = await koleksiNilaiRef
              .orderBy('tanggalinput', descending: true)
              .limit(1)
              .get();

          String capaianPengganti = '-'; // Nilai default jika tidak ada sisa nilai

          if (sisaNilaiSnapshot.docs.isNotEmpty) {
            capaianPengganti = sisaNilaiSnapshot.docs.first.data()['capaian'] ?? '-';
          }

          await siswaIndukRef.update({'capaian_terakhir': capaianPengganti});

          Get.snackbar("Berhasil", "Data nilai berhasil dihapus.");
          fetchDataNilai();

        } catch (e) {
          Get.snackbar("Error", "Gagal menghapus data: $e");
        } finally {
          isDialogLoading.value = false;
        }
      }
    );
  }

  Future<void> updateNilai(NilaiHalaqohUmi nilaiLama) async {
    isDialogLoading.value = true;
    try {
      final docRef = _getNilaiDocRef(nilaiLama.id);

      int nilaiNumerik = int.tryParse(nilaiEditC.text.trim()) ?? 0;
      if (nilaiNumerik > 98) nilaiNumerik = 98; // Terapkan validasi
      String gradeBaru = _getGrade(nilaiNumerik);
      
      final newData = {
        'hafalansurat': suratEditC.text,
        'ayathafalansurat': ayatEditC.text,
        'capaian': capaianEditC.text,
        'nilai': nilaiNumerik,
        'nilaihuruf': gradeBaru,
        'last_updated': FieldValue.serverTimestamp(),
      };

      await docRef.update(newData);
      
      // Update juga `capaian_terakhir` di dokumen induk siswa
      final siswaIndukRef = _getSiswaIndukRef();
      await siswaIndukRef.update({'capaian_terakhir': capaianEditC.text});

      Get.back(); // Tutup dialog edit
      Get.snackbar("Berhasil", "Data nilai berhasil diperbarui.");
      fetchDataNilai(); // Muat ulang daftar nilai

    } catch (e) {
      Get.snackbar("Error", "Gagal memperbarui data: $e");
    } finally {
      isDialogLoading.value = false;
    }
  }

   DocumentReference<Map<String, dynamic>> _getNilaiDocRef(String nilaiId) {
    // Fungsi ini sekarang langsung mengembalikan DocumentReference, bukan Future.
    return _getSiswaIndukRef().collection('nilai').doc(nilaiId);
  }
  
  // --- FUNGSI UTAMA (TIDAK BERUBAH, KARENA SUDAH MEMAKAI HELPER) ---
  Future<void> fetchDataNilai() async {
    try {
      isLoading.value = true;
      
      final nilaiSnapshot = await _getSiswaIndukRef()
          .collection('nilai')
          .orderBy('tanggalinput', descending: true)
          .get();
      
      daftarNilai.value = nilaiSnapshot.docs
          .map((doc) => NilaiHalaqohUmi.fromFirestore(doc))
          .toList();

    } catch (e) {
      Get.snackbar("Terjadi Kesalahan", "Tidak dapat memuat riwayat nilai siswa: $e");
    } finally {
      isLoading.value = false;
    }
  }

  DocumentReference _getSiswaIndukRef() {
    final idTahunAjaran = homeController.idTahunAjaran.value!;
    final semesterAktif = dataSiswa.value['semester'] ?? homeController.semesterAktifId.value;
    
    return firestore
        .collection('Sekolah').doc(homeController.idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelompokmengaji').doc(dataSiswa.value['fase'])
        .collection('pengampu').doc(dataSiswa.value['idpengampu']) // Menggunakan UID, sudah benar
        .collection('tempat').doc(dataSiswa.value['tempatmengaji'])
        .collection('semester').doc(semesterAktif)
        .collection('daftarsiswa').doc(dataSiswa.value['nisn']);
  }

  /// Helper untuk mendapatkan referensi dokumen nilai spesifik.
  DocumentReference getNilaiDocRef(String nilaiId) {
    return _getSiswaIndukRef().collection('nilai').doc(nilaiId);
  }


  // --- FUNGSI HELPER ---

  /// Helper untuk mendapatkan path TAHUN AJARAN terakhir (mencegah duplikasi)
  Future<String> getTahunAjaranTerakhir() async {
    final snapshot = await firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran')
        .orderBy('namatahunajaran', descending: true)
        .limit(1).get();
    if (snapshot.docs.isEmpty) throw Exception("Tidak ada data tahun ajaran");
    return snapshot.docs.first.data()['namatahunajaran'] as String;
  }        
}
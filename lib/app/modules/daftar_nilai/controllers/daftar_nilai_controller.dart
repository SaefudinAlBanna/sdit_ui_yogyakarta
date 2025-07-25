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
  final Map<String, dynamic> dataSiswa = Get.arguments;

  // --- STATE REAKTIF (mengikuti pola Al-Husna) ---
  var isLoading = true.obs;
  var isDialogLoading = false.obs; 
  var daftarNilai = <NilaiHalaqohUmi>[].obs; // List berisi model, bukan data mentah

   // --- CONTROLLER BARU UNTUK DIALOG EDIT ---
  late TextEditingController suratEditC;
  late TextEditingController ayatEditC;
  late TextEditingController capaianEditC;
  late TextEditingController nilaiEditC;
  late TextEditingController catatanEditC;
  // ... tambahkan controller lain jika perlu diedit

  //  bool get canEditOrDelete {
  //   final role = homeController.userRole.value;
  //   // HANYA Pengampu dan Koordinator yang boleh edit/hapus
  //   return role == 'Pengampu' || role == 'Koordinator Halaqoh' || role == 'Admin';
  // }
  bool get canEditOrDelete {
    // Pengampu yang bersangkutan, Koordinator, atau Admin boleh edit/hapus
    final user = homeController.auth.currentUser;
    if (user == null) return false;
    return user.uid == dataSiswa['idpengampu'] || homeController.canEditOrDeleteHalaqoh;
  }

  @override
  void onInit() {
    super.onInit();
    suratEditC = TextEditingController();
    ayatEditC = TextEditingController();
    capaianEditC = TextEditingController();
    nilaiEditC = TextEditingController();
    catatanEditC = TextEditingController();
    fetchDataNilai(); // Langsung panggil fungsi untuk memuat data
  }

  @override
  void onClose() {
    // Selalu dispose controller
    suratEditC.dispose(); ayatEditC.dispose();
    capaianEditC.dispose(); nilaiEditC.dispose();
    catatanEditC.dispose();
    super.onClose();
  }

  // Future<void> updateCatatanPengampu(NilaiHalaqohUmi nilai) async {
  //   if (catatanEditC.text == nilai.keteranganPengampu) {
  //     Get.back(); // Jika tidak ada perubahan, tutup saja
  //     return;
  //   }

  //   isDialogLoading.value = true;
  //   try {
  //     // Dapatkan path ke dokumen nilai yang spesifik
  //     final docRef = await _getNilaiDocRef(nilai.id);
  //     final namaPengedit = homeController.userRole.value ?? 'Admin'; 
  //     final uidPengedit = homeController.auth.currentUser!.uid;

  //     // Update hanya field keterangan dan timestamp
  //     await docRef.update({
  //       'keteranganpengampu': catatanEditC.text.trim(),
  //       'last_updated': FieldValue.serverTimestamp(),
  //       'terakhir_diubah': FieldValue.serverTimestamp(), // <-- REKAM JEJAK WAKTU
  //       'diubah_oleh_nama': namaPengedit,             // <-- REKAM JEJAK NAMA
  //       'diubah_oleh_uid': uidPengedit,               // <-- REKAM JEJAK UID
  //     });

  //     Get.back(); // Tutup dialog edit
  //     Get.snackbar("Berhasil", "Catatan pengampu berhasil diperbarui.");
  //     fetchDataNilai(); // Muat ulang daftar nilai untuk menampilkan data baru

  //   } catch (e) {
  //     Get.snackbar("Error", "Gagal memperbarui catatan: $e");
  //   } finally {
  //     isDialogLoading.value = false;
  //   }
  // }

  Future<void> updateCatatanPengampu(NilaiHalaqohUmi nilai) async {
    if (catatanEditC.text.trim() == nilai.keteranganPengampu) { Get.back(); return; }
    isDialogLoading.value = true;
    try {
      final docRef = await _getNilaiDocRef(nilai.id);
      
      // --- PERBAIKAN UTAMA DI SINI ---
      final uidPengedit = homeController.auth.currentUser!.uid;
      final docPengedit = await firestore.collection('Sekolah').doc(homeController.idSekolah).collection('pegawai').doc(uidPengedit).get();
      final aliasPengedit = docPengedit.data()?['alias'] ?? 'User';
      final rolePengedit = homeController.userRole.value ?? 'Role';
      final namaTampilanPengedit = "$aliasPengedit ($rolePengedit)";
      // --- AKHIR PERBAIKAN ---

      await docRef.update({
        'keteranganpengampu': catatanEditC.text.trim(),
        'terakhir_diubah': FieldValue.serverTimestamp(),
        'diubah_oleh_nama': namaTampilanPengedit, // <-- Simpan nama yang lebih informatif
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
        Get.back(); // Tutup dialog konfirmasi
        isDialogLoading.value = true;
        try {
          // --- LANGKAH 1: Dapatkan semua path yang dibutuhkan ---
          final docNilaiRef = await _getNilaiDocRef(nilai.id);
          final siswaIndukRef = await _getSiswaIndukRef();
          final koleksiNilaiRef = siswaIndukRef.collection('nilai');

          // --- LANGKAH 2: Hapus dokumen nilai yang dipilih ---
          await docNilaiRef.delete();

          // --- LANGKAH 3: Cari nilai terakhir yang tersisa ---
          final sisaNilaiSnapshot = await koleksiNilaiRef
              .orderBy('tanggalinput', descending: true)
              .limit(1)
              .get();

          String capaianPengganti = '-'; // Nilai default jika tidak ada sisa nilai

          // --- LANGKAH 4: Ambil keputusan ---
          if (sisaNilaiSnapshot.docs.isNotEmpty) {
            // Jika masih ada nilai lain, ambil capaian dari yang paling baru
            capaianPengganti = sisaNilaiSnapshot.docs.first.data()['capaian'] ?? '-';
          }

          // --- LANGKAH 5: Update dokumen induk siswa ---
          await siswaIndukRef.update({
            'capaian_terakhir': capaianPengganti,
          });

          Get.snackbar("Berhasil", "Data nilai berhasil dihapus.");
          fetchDataNilai(); // Muat ulang daftar nilai di halaman ini

        } catch (e) {
          Get.snackbar("Error", "Gagal menghapus data: $e");
        } finally {
          isDialogLoading.value = false;
        }
      }
    );
  }

  /// [FUNGSI BARU] Memperbarui dokumen nilai.
  Future<void> updateNilai(NilaiHalaqohUmi nilaiLama) async {
    isDialogLoading.value = true;
    try {
      final docRef = await _getNilaiDocRef(nilaiLama.id);

      int nilaiNumerik = int.tryParse(nilaiEditC.text.trim()) ?? 0;
      if (nilaiNumerik > 98) {
        nilaiNumerik = 98; // Terapkan validasi maks 98
      }

      String gradeBaru = _getGrade(nilaiNumerik);
      
      // Siapkan data baru dari controller edit
      final newData = {
        'hafalansurat': suratEditC.text,
        'ayathafalansurat': ayatEditC.text,
        'capaian': capaianEditC.text,
        'nilai': nilaiNumerik,
        'nilaihuruf': gradeBaru,
        'last_updated': FieldValue.serverTimestamp(),
      };

      await docRef.update(newData);
      
      // Update juga `capaian_terakhir` di dokumen induk jika field capaian diubah
      final siswaIndukRef = await _getSiswaIndukRef();
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

  // --- FUNGSI HELPER UNTUK MENDAPATKAN PATH ---

  /// Helper untuk mendapatkan path DOKUMEN NILAI yang spesifik.
  Future<DocumentReference<Map<String, dynamic>>> _getNilaiDocRef(String nilaiId) async {
    final siswaIndukRef = await _getSiswaIndukRef();
    return siswaIndukRef.collection('nilai').doc(nilaiId);
  }

  /// Helper untuk mendapatkan path DOKUMEN INDUK SISWA.
  DocumentReference _getSiswaIndukRef() {
    final idTahunAjaran = homeController.idTahunAjaran.value!;
    final semesterAktif = dataSiswa['semester'] ?? homeController.semesterAktifId.value;
    return firestore
        .collection('Sekolah').doc(homeController.idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelompokmengaji').doc(dataSiswa['fase'])
        .collection('pengampu').doc(dataSiswa['idpengampu']) // <-- MENGGUNAKAN UID
        .collection('tempat').doc(dataSiswa['tempatmengaji'])
        .collection('semester').doc(semesterAktif)
        .collection('daftarsiswa').doc(dataSiswa['nisn']);
  }


  /// Fungsi utama untuk mengambil semua data nilai siswa
  Future<void> fetchDataNilai() async {
    try {
      isLoading.value = true;
      final String nisn = dataSiswa['nisn'];
      
      // Menggunakan collectionGroup untuk mengambil semua nilai siswa, tidak peduli kelompoknya
      final nilaiSnapshot = await firestore
          .collectionGroup('nilai')
          .where('idsiswa', isEqualTo: nisn)
          .orderBy('tanggalinput', descending: true)
          .get();
      
      daftarNilai.value = nilaiSnapshot.docs
          .map((doc) => NilaiHalaqohUmi.fromFirestore(doc))
          .toList();

    } catch (e) {
      print("xx = $e");
      Get.snackbar("Terjadi Kesalahan", "Tidak dapat memuat riwayat nilai siswa. Mungkin perlu membuat index Firestore.");
    } finally {
      isLoading.value = false;
    }
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

  /// Helper untuk membangun path ke koleksi 'semester' (membuat `fetchDataNilai` lebih bersih)
  Future<CollectionReference<Map<String, dynamic>>> _getSemesterCollectionRef(
    String fase, String pengampu, String tempat, String nisn
  ) async {
    final tahunAjaran = await getTahunAjaranTerakhir();
    final idTahunAjaran = tahunAjaran.replaceAll("/", "-");

    return firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelompokmengaji').doc(fase)
        .collection('pengampu').doc(pengampu)
        .collection('tempat').doc(tempat) // <-- Penyesuaian untuk UMI
        .collection('daftarsiswa').doc(nisn)
        .collection('semester');
  }
}
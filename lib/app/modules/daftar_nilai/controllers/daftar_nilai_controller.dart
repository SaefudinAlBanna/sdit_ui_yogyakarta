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
  // ... tambahkan controller lain jika perlu diedit

  @override
  void onInit() {
    super.onInit();
    suratEditC = TextEditingController();
    ayatEditC = TextEditingController();
    capaianEditC = TextEditingController();
    nilaiEditC = TextEditingController();
    fetchDataNilai(); // Langsung panggil fungsi untuk memuat data
  }

  @override
  void onClose() {
    // Selalu dispose controller
    suratEditC.dispose(); ayatEditC.dispose();
    capaianEditC.dispose(); nilaiEditC.dispose();
    super.onClose();
  }

  //========================================================================
  // --- FUNGSI BARU UNTUK HAK AKSES, EDIT, DAN DELETE ---
  //========================================================================

  /// Getter untuk memeriksa apakah user saat ini boleh melakukan edit/delete.
  bool get canEditOrDelete {
    final role = homeController.userRole.value;
    return role == 'Pengampu' || role == 'Koordinator Halaqoh';
  }

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
  Future<DocumentReference<Map<String, dynamic>>> _getSiswaIndukRef() async {
    final idTahunAjaran = homeController.idTahunAjaran.value!;
    final semesterAktif = dataSiswa['semester'] ?? homeController.semesterAktifId.value;
    return firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelompokmengaji').doc(dataSiswa['fase'])
        .collection('pengampu').doc(dataSiswa['namapengampu'])
        .collection('tempat').doc(dataSiswa['tempatmengaji'])
        .collection('semester').doc(semesterAktif)
        .collection('daftarsiswa').doc(dataSiswa['nisn']);
  }


  /// Fungsi utama untuk mengambil semua data nilai siswa
  Future<void> fetchDataNilai() async {
    try {
      isLoading.value = true;
      
      // Ambil detail path dari dataSiswa argument
      final String idTahunAjaran = homeController.idTahunAjaran.value!;
      final String semesterAktif = dataSiswa['semester'] ?? homeController.semesterAktifId.value; // Prioritaskan semester dari argumen
      final String fase = dataSiswa['fase'];
      final String pengampu = dataSiswa['namapengampu'];
      final String tempat = dataSiswa['tempatmengaji'];
      final String nisn = dataSiswa['nisn'];

      // // 1. Dapatkan path ke koleksi 'semester' siswa
      // final semesterRef = await _getSemesterCollectionRef(fase, pengampu, tempat, nisn);

      // // 2. Ambil dokumen semester pertama (asumsi "Semester I" atau yang paling baru)
      // final semesterSnapshot = await semesterRef.orderBy('namasemester').limit(1).get();
      // if (semesterSnapshot.docs.isEmpty) {
      //   print("Siswa belum memiliki data semester.");
      //   daftarNilai.clear(); // Pastikan daftar kosong
      //   return; // Hentikan proses
      // }
      // final String idSemester = semesterSnapshot.docs.first.id;

      // 3. Ambil semua data 'nilai' dari dalam semester tersebut
       final nilaiSnapshot = await firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelompokmengaji').doc(fase)
          .collection('pengampu').doc(pengampu)
          .collection('tempat').doc(tempat)
          .collection('semester').doc(semesterAktif) // <-- INTEGRASI SEMESTER
          .collection('daftarsiswa').doc(nisn)
          .collection('nilai')
          .orderBy('tanggalinput', descending: true) // Urutkan berdasarkan tanggal
          .get();
      
      daftarNilai.value = nilaiSnapshot.docs
          .map((doc) => NilaiHalaqohUmi.fromFirestore(doc))
          .toList();

    } catch (e, s) {
      print("Error saat memuat data nilai: $e");
      print(s);
      Get.snackbar("Terjadi Kesalahan", "Tidak dapat memuat riwayat nilai siswa.");
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
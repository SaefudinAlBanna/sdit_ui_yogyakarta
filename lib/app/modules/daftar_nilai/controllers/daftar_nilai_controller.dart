import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/nilai_halaqoh_umi.dart';
import '../../home/controllers/home_controller.dart';
import 'package:flutter/material.dart';

class DaftarNilaiController extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeController = Get.find<HomeController>();
  final Rx<Map<String, dynamic>> dataSiswa = Rx<Map<String, dynamic>>({});

  var isLoading = true.obs;
  var isDialogLoading = false.obs;
  var daftarNilai = <NilaiHalaqohUmi>[].obs;

  late TextEditingController suratEditC, ayatEditC, capaianEditC, materiC, nilaiEditC, catatanEditC;

  bool get canEditOrDelete {
    final user = homeController.auth.currentUser;
    if (user == null) return false;
    // Ambil UID pengampu asli jika ini adalah sesi pengganti
    final idPengampuAsli = dataSiswa.value['idPengampuAsli'] ?? dataSiswa.value['idpengampu'];
    return user.uid == idPengampuAsli || homeController.canEditOrDeleteHalaqoh;
  }

   @override
  void onInit() {
    super.onInit();
    suratEditC = TextEditingController(); ayatEditC = TextEditingController();
    capaianEditC = TextEditingController(); materiC = TextEditingController();
    nilaiEditC = TextEditingController(); catatanEditC = TextEditingController();

    final Map<String, dynamic>? args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      dataSiswa.value = args;
      fetchDataNilai();
    } else {
      Get.snackbar("Error", "Gagal memuat data siswa.");
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    suratEditC.dispose(); ayatEditC.dispose();
    capaianEditC.dispose(); nilaiEditC.dispose();
    catatanEditC.dispose();
    materiC.dispose();
    super.onClose();
  }

  // --- FUNGSI UTAMA ---

  Future<void> fetchDataNilai() async {
    try {
      isLoading.value = true;
      final nilaiSnapshot = await _getSiswaIndukRef()
          .collection('nilai') // <-- [DIKEMBALIKAN] Menggunakan koleksi 'nilai'
          .get();
      
      // Mengurutkan di sisi klien untuk menangani berbagai format tanggal
      var listNilai = nilaiSnapshot.docs
          .map((doc) => NilaiHalaqohUmi.fromFirestore(doc))
          .toList();
      
      listNilai.sort((a, b) => b.tanggalInput.compareTo(a.tanggalInput));
      
      daftarNilai.value = listNilai;

    } catch (e, stackTrace) {
      // [PENTING] Logging error yang detail
      print("--- ERROR KRITIS FETCH DATA NILAI ---");
      print(e);
      print(stackTrace);
      Get.snackbar("Terjadi Kesalahan", "Gagal memuat riwayat nilai. Cek debug console.");
    } finally {
      isLoading.value = false;
    }
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
  
      // [PERBAIKAN KUNCI DI SINI]
      await docRef.update({
        'keterangan': catatanEditC.text.trim(), // <-- Menggunakan nama field yang BENAR
        'terakhir_diubah': FieldValue.serverTimestamp(),
        'diubah_oleh_nama': namaTampilanPengedit,
        'diubah_oleh_uid': uidPengedit,
      });
  
      Get.back();
      Get.snackbar("Berhasil", "Catatan pengampu berhasil diperbarui.");
      fetchDataNilai(); // Refresh UI
  
    } catch (e) {
      Get.snackbar("Error", "Gagal memperbarui catatan: $e");
    } finally {
      isDialogLoading.value = false;
    }
  }
  
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
          // Langkah 1: Hapus dokumen nilai yang dipilih
          await _getNilaiDocRef(nilai.id).delete();
          Get.snackbar("Info", "Data nilai telah dihapus.");

          // Langkah 2: Cari nilai terbaru yang TERSISA
          final siswaIndukRef = _getSiswaIndukRef();
          final sisaNilaiSnapshot = await siswaIndukRef
              .collection('nilai') // Pastikan membaca dari koleksi 'nilai'
              .orderBy('tanggal_input', descending: true) // Urutkan dari yang paling baru
              .limit(1) // Ambil 1 teratas
              .get();

          // Langkah 3: Tentukan apa yang akan menjadi capaian baru
          String capaianPengganti = ''; // Defaultnya kosong jika tidak ada nilai tersisa

          if (sisaNilaiSnapshot.docs.isNotEmpty) {
            // Jika ada sisa nilai, ambil capaian dari dokumen terbaru itu
            final dataNilaiTerbaru = sisaNilaiSnapshot.docs.first.data();
            capaianPengganti = dataNilaiTerbaru['capaian'] ?? '';
          }

          // Langkah 4: Update dokumen induk siswa dengan capaian baru
          await siswaIndukRef.update({
            'capaian': capaianPengganti,
            'capaian_terakhir': capaianPengganti
          });

          // Langkah 5: Muat ulang data di UI untuk menampilkan hasilnya
          fetchDataNilai(); 

        } catch (e) {
          Get.snackbar("Error", "Gagal memperbarui status capaian: $e");
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

      // [PERBAIKAN] Gunakan nama field yang BENAR sesuai standar kita
      final newData = {
        'surat': suratEditC.text,       // sebelumnya: hafalansurat
        'ayat': ayatEditC.text,         // sebelumnya: ayathafalansurat
        'capaian': capaianEditC.text,
        'materi': materiC.text,         // <-- BARU
        'nilai': nilaiNumerik,
        'grade': _getGrade(nilaiNumerik), // sebelumnya: nilaihuruf
        'terakhir_diubah': FieldValue.serverTimestamp(),
      };

      await docRef.update(newData);

      // Update juga `capaian_terakhir` di dokumen induk siswa
      final siswaIndukRef = _getSiswaIndukRef();
      await siswaIndukRef.update({
        'capaian': capaianEditC.text,
        'capaian_terakhir': capaianEditC.text
      });

      Get.back(); // Tutup dialog edit
      Get.snackbar("Berhasil", "Data nilai berhasil diperbarui.");
      fetchDataNilai(); // Muat ulang daftar nilai

    } catch (e) {
      Get.snackbar("Error", "Gagal memperbarui data: $e");
    } finally {
      isDialogLoading.value = false;
    }
  }

  // --- FUNGSI HELPER ---

  // DocumentReference _getSiswaIndukRef() {
  //   final idTahunAjaran = homeController.idTahunAjaran.value!;
  //   final semesterAktif = dataSiswa.value['semester'] ?? homeController.semesterAktifId.value;
  //   // [PERBAIKAN] Gunakan UID pengampu yang benar, terutama untuk sesi pengganti
  //   final idPengampuUntukQuery = dataSiswa.value['idPengampuAsli'] ?? dataSiswa.value['idpengampu'];
    
  //   return firestore
  //       .collection('Sekolah').doc(homeController.idSekolah)
  //       .collection('tahunajaran').doc(idTahunAjaran)
  //       .collection('kelompokmengaji').doc(dataSiswa.value['fase'])
  //       .collection('pengampu').doc(idPengampuUntukQuery) // Menggunakan ID yang sudah divalidasi
  //       .collection('tempat').doc(dataSiswa.value['tempatmengaji'])
  //       .collection('semester').doc(semesterAktif)
  //       .collection('daftarsiswa').doc(dataSiswa.value['nisn']);
  // }

  DocumentReference _getSiswaIndukRef() {
    final idTahunAjaran = homeController.idTahunAjaran.value!;
    
    // [PERBAIKAN FINAL] Ambil semua data dari argumen yang sudah diperkaya
    final args = dataSiswa.value;
    final semesterAktif = args['semester'] ?? homeController.semesterAktifId.value;
    final fase = args['fase'];
    final tempat = args['tempatmengaji'];
    final nisn = args['nisn'];
    
    // Logika cerdas: Prioritaskan idPengampuAsli jika ada (untuk kasus guru pengganti),
    // jika tidak, gunakan idpengampu biasa.
    final idPengampuUntukQuery = args['idPengampuAsli'] ?? args['idpengampu'];
  
    // Pastikan tidak ada yang null sebelum membangun path
    if (fase == null || tempat == null || nisn == null || idPengampuUntukQuery == null) {
      // Lemparkan error yang jelas jika data tidak lengkap
      throw Exception("Argumen tidak lengkap untuk membangun path Firestore.");
    }
    
    return firestore
        .collection('Sekolah').doc(homeController.idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelompokmengaji').doc(fase)
        .collection('pengampu').doc(idPengampuUntukQuery)
        .collection('tempat').doc(tempat)
        .collection('semester').doc(semesterAktif)
        .collection('daftarsiswa').doc(nisn);
  }

  /// Helper untuk mendapatkan referensi dokumen nilai spesifik.
  DocumentReference _getNilaiDocRef(String nilaiId) {
    return _getSiswaIndukRef().collection('nilai').doc(nilaiId);
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
}
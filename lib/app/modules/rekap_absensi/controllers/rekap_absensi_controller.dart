import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../home/controllers/home_controller.dart';
import '../../../models/rekap_absensi_model.dart';

class RekapAbsensiController extends GetxController {
  
  // --- DEPENDENSI & DATA DASAR ---
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();

  String? idKelas;

  // late String idKelas;
  late String idTahunAjaran;
  late String semesterAktif;

  // --- STATE MANAGEMENT UNTUK UI ---
  final RxBool isLoading = false.obs;
  
  // Tanggal default: 1 bulan terakhir
  final Rx<DateTime> tanggalMulai = DateTime.now().subtract(const Duration(days: 30)).obs;
  final Rx<DateTime> tanggalSelesai = DateTime.now().obs;

  // Hasil akhir yang akan ditampilkan di View
  final RxList<RekapAbsensiSiswaModel> rekapData = <RekapAbsensiSiswaModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Ambil data dari argumen navigasi (saat wali kelas klik menu ini)
    if (Get.arguments != null && Get.arguments is Map<String, dynamic>) {
      idKelas = Get.arguments['idKelas'];
    }
    
    idTahunAjaran = homeC.idTahunAjaran.value!;
    semesterAktif = homeC.semesterAktifId.value;
  }

  // --- FUNGSI UTAMA: Menghitung Rekapitulasi ---
  Future<void> getRekapAbsensi() async {

    if (idKelas == null || idKelas!.isEmpty) {
      Get.snackbar("Error Kritis", "ID Kelas tidak terdefinisi. Silakan coba lagi.");
      return;
    }

    if (tanggalMulai.value.isAfter(tanggalSelesai.value)) {
      Get.snackbar("Peringatan", "Tanggal mulai tidak boleh setelah tanggal selesai.");
      return;
    }

    isLoading.value = true;
    rekapData.clear();

    try {
      // LANGKAH 1: Ambil daftar siswa di kelas ini
      final siswaSnapshot = await firestore.collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelastahunajaran').doc(idKelas!)
        .collection('semester').doc(semesterAktif)
        .collection('daftarsiswa').get();
      
      if (siswaSnapshot.docs.isEmpty) {
        Get.snackbar("Info", "Tidak ada siswa di kelas ini.");
        isLoading.value = false;
        return;
      }
      
      // Simpan data siswa (ID dan Nama) untuk digunakan nanti
      final Map<String, String> dataSiswa = {
        for (var doc in siswaSnapshot.docs) doc.id: doc.data()['namasiswa'] ?? 'Tanpa Nama'
      };

      // LANGKAH 2: Siapkan wadah untuk menghitung (ID Siswa -> Map Status)
      Map<String, Map<String, int>> hitunganSementara = {
        for (var idSiswa in dataSiswa.keys) idSiswa: {'S': 0, 'I': 0, 'A': 0}
      };

      // LANGKAH 3: Loop melalui setiap hari dalam rentang tanggal
      for (var tgl = tanggalMulai.value; tgl.isBefore(tanggalSelesai.value.add(const Duration(days: 1))); tgl = tgl.add(const Duration(days: 1))) {
        String tanggalDocId = DateFormat('yyyy-MM-dd').format(tgl);
        
        final absensiDoc = await firestore.collection('Sekolah').doc(homeC.idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelastahunajaran').doc(idKelas)
          .collection('semester').doc(semesterAktif)
          .collection('absensi').doc(tanggalDocId).get();
        
        if (absensiDoc.exists) {
          Map<String, dynamic> dataAbsensi = absensiDoc.data()?['siswa'] ?? {};
          // Proses setiap absensi siswa pada hari itu
          dataAbsensi.forEach((idSiswa, status) {
            if (hitunganSementara.containsKey(idSiswa)) {
              if (status == 'Sakit') hitunganSementara[idSiswa]!['S'] = (hitunganSementara[idSiswa]!['S'] ?? 0) + 1;
              if (status == 'Izin') hitunganSementara[idSiswa]!['I'] = (hitunganSementara[idSiswa]!['I'] ?? 0) + 1;
              if (status == 'Alfa') hitunganSementara[idSiswa]!['A'] = (hitunganSementara[idSiswa]!['A'] ?? 0) + 1;
            }
          });
        }
      }

      // LANGKAH 4: Konversi hasil hitungan ke format Model yang rapi
      List<RekapAbsensiSiswaModel> hasilAkhir = [];
      dataSiswa.forEach((idSiswa, namaSiswa) {
        hasilAkhir.add(RekapAbsensiSiswaModel(
          idSiswa: idSiswa,
          namaSiswa: namaSiswa,
          sakitCount: hitunganSementara[idSiswa]!['S'] ?? 0,
          izinCount: hitunganSementara[idSiswa]!['I'] ?? 0,
          alfaCount: hitunganSementara[idSiswa]!['A'] ?? 0,
        ));
      });
      
      rekapData.assignAll(hasilAkhir);

    } catch (e) {
      Get.snackbar("Error", "Gagal mengambil rekap absensi: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // --- FUNGSI UNTUK UI: Memilih Tanggal ---
  Future<void> pilihTanggalMulai(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: tanggalMulai.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != tanggalMulai.value) {
      tanggalMulai.value = picked;
    }
  }

  Future<void> pilihTanggalSelesai(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: tanggalSelesai.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != tanggalSelesai.value) {
      tanggalSelesai.value = picked;
    }
  }
}
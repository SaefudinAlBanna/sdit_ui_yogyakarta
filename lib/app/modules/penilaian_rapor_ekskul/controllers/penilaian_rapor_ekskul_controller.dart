// File: lib/app/modules/penilaian_rapor_ekskul/controllers/penilaian_rapor_ekskul_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/siswa_model.dart';
import 'package:get/get.dart';
import 'package:sdit_ui_yogyakarta/app/modules/home/controllers/home_controller.dart';

// Helper class untuk mengelola state per baris secara reaktif
class NilaiRaporSiswa {
  SiswaModel siswa;
  Rxn<String> predikat;
  RxString keterangan;
  RxBool isSelected = false.obs; // Untuk checkbox aksi massal

  NilaiRaporSiswa({required this.siswa, String? predikatAwal, String? keteranganAwal})
      : predikat = Rxn<String>(predikatAwal),
        keterangan = RxString(keteranganAwal ?? '');
}

class PenilaianRaporEkskulController extends GetxController {
  final String instanceEkskulId;
  PenilaianRaporEkskulController({required this.instanceEkskulId});

  // Dependensi
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();

  // State Utama
  final RxBool isLoading = true.obs;
  final RxList<NilaiRaporSiswa> daftarNilaiSiswa = <NilaiRaporSiswa>[].obs;
  final List<String> predikatOptions = ['Sangat Baik', 'Baik', 'Cukup', 'Kurang'];
  
  // State Aksi Massal
  final TextEditingController templateKeteranganC = TextEditingController();
  final RxBool isSelectAll = false.obs;

  late final CollectionReference _anggotaRef;
  late final String _semesterField; // cth: "nilaiSemester1"

  @override
  void onInit() {
    super.onInit();
    final idSekolah = homeC.idSekolah;
    final idTahunAjaran = homeC.idTahunAjaran.value!;
    _semesterField = "nilaiSemester${homeC.semesterAktifId.value}";

    _anggotaRef = _firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('ekstrakurikuler').doc(instanceEkskulId)
        .collection('anggota');
        
    fetchDataAwal();
  }


  // Future<void> fetchDataAwal() async {
  //   isLoading.value = true;
  //   debugPrint("[DEBUG] ==> Memulai fetchDataAwal...");
  //   try {
  //     // Kembalikan orderBy jika Anda mau, atau biarkan tanpa itu untuk tes ini.
  //     // Kita akan bisa melihat errornya apa pun yang terjadi.
  //     final anggotaSnapshot = await _anggotaRef.orderBy('namaSiswa').get();
  //     debugPrint("[DEBUG] Query anggota selesai. Ditemukan ${anggotaSnapshot.docs.length} dokumen.");
      
  //     final List<NilaiRaporSiswa> tempList = [];
      
  //     // Loop akan dimulai di sini
  //     for (final doc in anggotaSnapshot.docs) {
        
  //       // --- ALAT SADAP AKTIF ---
  //       debugPrint("----------------------------------------------------");
  //       debugPrint("[DEBUG] Memproses dokumen dengan ID: ${doc.id}");
  //       debugPrint("[DEBUG] Data mentah: ${doc.data()}");
  //       // --- AKHIR ALAT SADAP ---

  //       final data = doc.data() as Map<String, dynamic>;

  //       debugPrint("[DEBUG] Parsing 'namaSiswa': ${data['namaSiswa']}");
  //       debugPrint("[DEBUG] Parsing 'idKelasSiswa': ${data['idKelasSiswa']}");
  //       debugPrint("[DEBUG] Parsing 'kelasSiswa': ${data['kelasSiswa']}");

  //       final siswa = SiswaModel(
  //           nisn: doc.id,
  //           nama: data['namaSiswa'] ?? 'Tanpa Nama',
  //           idKelas: data['idKelasSiswa'] ?? '',
  //           namaKelas: data['kelasSiswa'] ?? 'Tanpa Kelas'
  //       );
        
  //       debugPrint("[DEBUG] Obyek SiswaModel berhasil dibuat untuk: ${siswa.nama}");

  //       final nilaiData = data[_semesterField] as Map<String, dynamic>?;
  //       debugPrint("[DEBUG] Data nilai untuk semester '$_semesterField': $nilaiData");

  //       tempList.add(NilaiRaporSiswa(
  //         siswa: siswa,
  //         predikatAwal: nilaiData?['predikat'],
  //         keteranganAwal: nilaiData?['keterangan'],
  //       ));
  //       debugPrint("[DEBUG] Obyek NilaiRaporSiswa berhasil ditambahkan ke list.");
  //     }
      
  //     daftarNilaiSiswa.value = tempList;
  //     debugPrint("[DEBUG] ==> Semua data berhasil diproses.");

  //   } catch (e, stackTrace) { // Tangkap juga stack trace untuk info lebih detail
  //     debugPrint("[DEBUG] !!!!!! ERROR KRITIS TERJADI !!!!!!");
  //     debugPrint("[DEBUG] Error: $e");
  //     debugPrint("[DEBUG] Stack Trace: $stackTrace");
  //     Get.snackbar("Error", "Gagal memuat data anggota: $e");
  //   } finally {
  //     isLoading.value = false;
  //     debugPrint("[DEBUG] ==> fetchDataAwal selesai. isLoading diatur ke false.");
  //   }
  // }


  Future<void> fetchDataAwal() async {
    isLoading.value = true;
    try {
      final anggotaSnapshot = await _anggotaRef.orderBy('namaSiswa').get();
      
      final List<NilaiRaporSiswa> tempList = [];
      for (final doc in anggotaSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // --- PERBAIKAN DENGAN JARING PENGAMAN NULL DI SINI ---
        final siswa = SiswaModel(
            nisn: doc.id,
            // Jika 'namaSiswa' null, gunakan 'Tanpa Nama' sebagai pengganti
            nama: data['namaSiswa'] ?? 'Tanpa Nama',
            // Jika 'idKelasSiswa' null, gunakan string kosong
            idKelas: data['idKelasSiswa'] ?? '',
            // Jika 'kelasSiswa' null, gunakan 'Tanpa Kelas'
            namaKelas: data['kelasSiswa'] ?? 'Tanpa Kelas'
        );
        // --- AKHIR PERBAIKAN ---
        
        final nilaiData = data[_semesterField] as Map<String, dynamic>?;

        tempList.add(NilaiRaporSiswa(
          siswa: siswa,
          predikatAwal: nilaiData?['predikat'],
          keteranganAwal: nilaiData?['keterangan'],
        ));
      }
      daftarNilaiSiswa.value = tempList;
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data anggota: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void toggleSelectAll(bool? value) {
    isSelectAll.value = value ?? false;
    for (var item in daftarNilaiSiswa) {
      item.isSelected.value = isSelectAll.value;
    }
  }

  void terapkanTemplateKeTerpilih() {
    final template = templateKeteranganC.text;
    if (template.isEmpty) {
      Get.snackbar("Info", "Template keterangan masih kosong.");
      return;
    }
    int count = 0;
    for (var item in daftarNilaiSiswa) {
      if (item.isSelected.value) {
        item.keterangan.value = template;
        count++;
      }
    }
    if (count > 0) {
      Get.snackbar("Berhasil", "Template diterapkan ke $count siswa terpilih.");
    } else {
      Get.snackbar("Info", "Tidak ada siswa yang dipilih.");
    }
  }

  void hapusNilaiTerpilih() {
    int count = 0;
    for (var item in daftarNilaiSiswa) {
      if (item.isSelected.value) {
        item.predikat.value = null;
        item.keterangan.value = '';
        count++;
      }
    }
     if (count > 0) {
      Get.snackbar("Berhasil", "Nilai untuk $count siswa terpilih telah dihapus.");
    } else {
      Get.snackbar("Info", "Tidak ada siswa yang dipilih.");
    }
  }
  
  Future<void> simpanSemuaPerubahan() async {
    isLoading.value = true;
    try {
      final batch = _firestore.batch();
      for (final item in daftarNilaiSiswa) {
        final docRef = _anggotaRef.doc(item.siswa.nisn);
        
        // Gunakan dot notation untuk update field di dalam Map
        batch.update(docRef, {
          _semesterField: {
            'predikat': item.predikat.value,
            'keterangan': item.keterangan.value,
          }
        });
      }
      await batch.commit();
      Get.back(); // Kembali ke halaman detail pembina
      Get.snackbar("Berhasil", "Semua perubahan nilai rapor berhasil disimpan.");
    } catch (e) {
      Get.snackbar("Error Kritis", "Gagal menyimpan perubahan: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
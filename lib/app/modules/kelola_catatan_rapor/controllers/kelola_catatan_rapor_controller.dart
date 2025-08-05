// File: lib/app/modules/kelola_catatan_rapor/controllers/kelola_catatan_rapor_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdit_ui_yogyakarta/app/modules/home/controllers/home_controller.dart';

import '../../../models/siswa_model.dart';

// Helper class untuk mengelola state per baris di UI secara reaktif
class CatatanRaporSiswa {
  SiswaModel siswa;
  String catatanAwal;
  RxString catatan;      // Catatan yang bisa diedit
  RxBool isSelected; // Untuk checkbox

  CatatanRaporSiswa({required this.siswa, String? catatanAwal})
      : catatan = RxString(catatanAwal ?? ''),
        this.catatanAwal = catatanAwal ?? '', 
        isSelected = false.obs;

        bool get isChanged => catatan.value != catatanAwal;

}

class KelolaCatatanRaporController extends GetxController {
  final String idKelas;
  KelolaCatatanRaporController({required this.idKelas});

  // --- DEPENDENSI ---
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();

  // --- STATE UTAMA ---
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxList<CatatanRaporSiswa> daftarSiswaUntukCatatan = <CatatanRaporSiswa>[].obs;
  
  // --- STATE AKSI MASSAL ---
  final TextEditingController templateCatatanC = TextEditingController();
  final RxBool isSelectAll = false.obs;

  late final CollectionReference _siswaCollectionRef;
  late final String _semesterField;

  @override
  void onInit() {
    super.onInit();
    final idTahunAjaran = homeC.idTahunAjaran.value!;
    _semesterField = homeC.semesterAktifId.value; // cth: "1" atau "2"

    _siswaCollectionRef = _firestore
        .collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelastahunajaran').doc(idKelas)
        .collection('semester').doc(_semesterField)
        .collection('daftarsiswa');
        
    fetchDataAwal();
  }
  
  @override
  void onClose() {
    templateCatatanC.dispose();
    super.onClose();
  }

  /// Mengambil daftar siswa dan catatan rapor mereka yang sudah ada.
  Future<void> fetchDataAwal() async {
    isLoading.value = true;
    try {
      final siswaSnapshot = await _siswaCollectionRef.orderBy('namasiswa').get();
      
      final List<CatatanRaporSiswa> tempList = [];
      for (final doc in siswaSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final siswa = SiswaModel(
            nisn: doc.id,
            nama: data['namasiswa'] ?? 'Tanpa Nama',
            idKelas: idKelas,
            namaKelas: idKelas); // Di sini, idKelas dan namaKelas sama
        
        // Ambil catatan yang sudah ada dari field `catatan_wali_kelas`
        final String catatanAwal = data['catatan_wali_kelas'] ?? '';

        tempList.add(CatatanRaporSiswa(siswa: siswa, catatanAwal: catatanAwal));
      }
      daftarSiswaUntukCatatan.value = tempList;
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data siswa: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Mengaktifkan/menonaktifkan semua checkbox.
  void toggleSelectAll(bool? value) {
    isSelectAll.value = value ?? false;
    for (var item in daftarSiswaUntukCatatan) {
      item.isSelected.value = isSelectAll.value;
    }
  }

  /// Menerapkan template ke semua siswa yang dipilih.
  void terapkanTemplateKeTerpilih() {
    final template = templateCatatanC.text;
    
    // --- PENJAGA 1: Cek apakah ada siswa yang dipilih ---
    final siswaTerpilih = daftarSiswaUntukCatatan.where((item) => item.isSelected.value).toList();
    if (siswaTerpilih.isEmpty) {
      Get.snackbar(
        "Peringatan", 
        "Tidak ada siswa yang dipilih. Silakan centang siswa terlebih dahulu.",
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return; // Hentikan eksekusi
    }
    // ---------------------------------------------------

    // --- PENJAGA 2: Cek apakah template kosong ---
    if (template.isEmpty) {
      Get.snackbar("Info", "Template catatan masih kosong.");
      return; // Hentikan eksekusi
    }
    // ---------------------------------------------
    
    int count = 0;
    // Loop sekarang menggunakan list yang sudah difilter, lebih efisien
    for (var item in siswaTerpilih) {
      item.catatan.value = template;
      count++;
    }
    
    Get.snackbar("Berhasil", "Template diterapkan ke $count siswa terpilih.", backgroundColor: Colors.green);
  }

  /// Menghapus catatan untuk semua siswa yang dipilih.
  void hapusCatatanTerpilih() {
    int count = 0;
    for (var item in daftarSiswaUntukCatatan) {
      if (item.isSelected.value) {
        item.catatan.value = ''; // Cukup kosongkan stringnya
        count++;
      }
    }
    Get.snackbar("Berhasil", "Catatan untuk $count siswa terpilih telah dihapus.");
  }
  
  /// Menyimpan semua perubahan ke Firestore menggunakan WriteBatch.
  // Future<void> simpanSemuaPerubahan() async {
  //   isSaving.value = true;
  //   try {
  //     final batch = _firestore.batch();
      
  //     for (final item in daftarSiswaUntukCatatan) {
  //       final docRef = _siswaCollectionRef.doc(item.siswa.nisn);
  //       batch.update(docRef, {'catatan_wali_kelas': item.catatan.value});
  //     }
      
  //     await batch.commit();
      
  //     Get.back(); // Kembali ke halaman sebelumnya
  //     Get.snackbar("Berhasil", "Semua catatan rapor berhasil disimpan.", backgroundColor: Colors.green);
  //   } catch (e) {
  //     Get.snackbar("Error Kritis", "Gagal menyimpan perubahan: $e");
  //   } finally {
  //     isSaving.value = false;
  //   }
  // }

  Future<void> simpanSemuaPerubahan() async {
    isSaving.value = true;
    try {
      final batch = _firestore.batch();
      int changesCount = 0;
      
      for (final item in daftarSiswaUntukCatatan) {
        // --- PERBAIKAN UTAMA DI SINI ---
        // Hanya update dokumen jika nilainya berubah dari awal
        if (item.isChanged) {
          final docRef = _siswaCollectionRef.doc(item.siswa.nisn);
          batch.update(docRef, {'catatan_wali_kelas': item.catatan.value});
          changesCount++;
        }
        // -----------------------------
      }

      if (changesCount == 0) {
        Get.snackbar("Info", "Tidak ada perubahan yang perlu disimpan.");
        isSaving.value = false;
        return;
      }
      
      await batch.commit();
      
      Get.back();
      Get.snackbar("Berhasil", "$changesCount catatan rapor berhasil diperbarui.", backgroundColor: Colors.green);
    } catch (e) {
      Get.snackbar("Error Kritis", "Gagal menyimpan perubahan: $e");
    } finally {
      isSaving.value = false;
    }
  }
}
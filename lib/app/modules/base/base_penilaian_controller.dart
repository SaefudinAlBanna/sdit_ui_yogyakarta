// File: lib/app/modules/base/base_penilaian_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdit_ui_yogyakarta/app/modules/home/controllers/home_controller.dart';
import '../../models/siswa_model.dart';
import 'penilaian_siswa_item.dart';

abstract class BasePenilaianController<T> extends GetxController {
  // --- DEPENDENSI ---
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();

  // --- STATE UMUM ---
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxList<PenilaianSiswaItem<T>> daftarPenilaian = <PenilaianSiswaItem<T>>[].obs;
  final TextEditingController templateKeteranganC = TextEditingController();
  final RxBool isSelectAll = false.obs;

  // --- METODE ABSTRAK (KONTRAK YANG HARUS DIISI OLEH ANAK) ---
  /// Mengambil daftar siswa yang akan dinilai.
  Future<List<SiswaModel>> getSiswaList();
  /// Mengambil data penilaian yang sudah ada untuk seorang siswa.
  Future<Map<String, dynamic>?> getExistingPenilaian(String nisn);
  /// Mengurai nilai (tipe T) dari data Firestore.
  T? parseNilai(Map<String, dynamic> data);
  /// Mengurai keterangan (String) dari data Firestore.
  String? parseKeterangan(Map<String, dynamic> data);
  /// Membangun Map yang akan disimpan ke Firestore.
  Map<String, dynamic> buildUpdateData(T? nilai, String keterangan);
  /// Mendapatkan path dokumen Firestore yang akan di-update.
  DocumentReference getFirestoreDocRef(String nisn);

  @override
  void onInit() {
    super.onInit();
    loadData();
  }
  
  @override
  void onClose() {
    templateKeteranganC.dispose();
    super.onClose();
  }

  /// [ORKESTRATOR] Fungsi utama untuk memuat semua data.
  Future<void> loadData() async {
    isLoading.value = true;
    try {
      final siswaList = await getSiswaList();
      final List<PenilaianSiswaItem<T>> tempList = [];
      for (final siswa in siswaList) {
        final existingData = await getExistingPenilaian(siswa.nisn);
        tempList.add(PenilaianSiswaItem<T>(
          siswa: siswa,
          nilaiAwal: existingData != null ? parseNilai(existingData) : null,
          keteranganAwal: existingData != null ? parseKeterangan(existingData) ?? '' : '',
        ));
      }
      daftarPenilaian.value = tempList;
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // --- METODE UMUM (LOGIKA YANG SAMA UNTUK SEMUA) ---
  void toggleSelectAll(bool? value) {
    isSelectAll.value = value ?? false;
    for (var item in daftarPenilaian) {
      item.isSelected.value = isSelectAll.value;
    }
  }

  void terapkanTemplateKeTerpilih() {
    final siswaTerpilih = daftarPenilaian.where((i) => i.isSelected.value).toList();
    if (siswaTerpilih.isEmpty) {
      Get.snackbar("Peringatan", "Tidak ada siswa yang dipilih.");
      return;
    }
    for (var item in siswaTerpilih) {
      item.keterangan.value = templateKeteranganC.text;
    }
    Get.snackbar("Berhasil", "Template diterapkan ke ${siswaTerpilih.length} siswa.");
  }

  void hapusNilaiTerpilih() {
     final siswaTerpilih = daftarPenilaian.where((i) => i.isSelected.value).toList();
     if (siswaTerpilih.isEmpty) return;
     for (var item in siswaTerpilih) {
      item.nilai.value = null;
      item.keterangan.value = '';
    }
  }

  Future<void> simpanSemuaPerubahan() async {
    isSaving.value = true;
    try {
      final batch = firestore.batch();
      int changesCount = 0;
      for (final item in daftarPenilaian) {
        if (item.isChanged) {
          final docRef = getFirestoreDocRef(item.siswa.nisn);
          final updateData = buildUpdateData(item.nilai.value, item.keterangan.value);
          batch.update(docRef, updateData);
          changesCount++;
        }
      }

      if (changesCount == 0) {
        Get.snackbar("Info", "Tidak ada perubahan untuk disimpan.");
      } else {
        await batch.commit();
        Get.back();
        Get.snackbar("Berhasil", "$changesCount data nilai berhasil diperbarui.");
      }
    } catch (e) {
      Get.snackbar("Error Kritis", "Gagal menyimpan perubahan: $e");
    } finally {
      isSaving.value = false;
    }
  }
}
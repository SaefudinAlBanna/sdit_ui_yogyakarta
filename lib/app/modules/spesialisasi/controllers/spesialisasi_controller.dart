// File: lib/app/modules/admin_manajemen/controllers/spesialisasi_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../models/spesialisasi_model.dart';

class SpesialisasiController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  
  final TextEditingController namaC = TextEditingController();
  final RxBool isLoading = false.obs;
  final RxList<SpesialisasiModel> daftarSpesialisasi = <SpesialisasiModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchSpesialisasi();
  }

  Future<void> fetchSpesialisasi() async {
    try {
      isLoading.value = true;
      final snapshot = await _firestore
          .collection('master_spesialisasi')
          .where('status', isEqualTo: 'Aktif') // Hanya ambil yang aktif
          .orderBy('namaSpesialisasi', descending: false)
          .get();

      daftarSpesialisasi.value = snapshot.docs
          .map((doc) => SpesialisasiModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print(e);
      Get.snackbar('Error', 'Gagal memuat data: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addSpesialisasi() async {
    if (namaC.text.isEmpty) {
      Get.snackbar('Peringatan', 'Nama spesialisasi tidak boleh kosong.');
      return;
    }

    try {
      isLoading.value = true;
      final newId = _uuid.v4();
      final now = Timestamp.now();
      final newSpesialisasi = SpesialisasiModel(
        id: newId,
        namaSpesialisasi: namaC.text,
        status: 'Aktif',
        dibuatPada: now,
        diubahPada: now,
      );

      await _firestore
          .collection('master_spesialisasi')
          .doc(newId)
          .set(newSpesialisasi.toFirestore());
      
      Get.back(); // Tutup dialog
      await fetchSpesialisasi(); // Muat ulang data
      Get.snackbar('Berhasil', 'Spesialisasi berhasil ditambahkan.');
    } catch (e) {
      Get.snackbar('Error', 'Gagal menambah data: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateSpesialisasi(String id, String namaBaru) async {
     if (namaBaru.isEmpty) {
      Get.snackbar('Peringatan', 'Nama spesialisasi tidak boleh kosong.');
      return;
    }
    
    try {
       await _firestore.collection('master_spesialisasi').doc(id).update({
        'namaSpesialisasi': namaBaru,
        'diubahPada': FieldValue.serverTimestamp(),
       });
       Get.back(); // Tutup dialog
       await fetchSpesialisasi();
       Get.snackbar('Berhasil', 'Spesialisasi berhasil diperbarui.');
    } catch(e) {
       Get.snackbar('Error', 'Gagal memperbarui data: ${e.toString()}');
    }
  }

  Future<void> deleteSpesialisasi(String id) async {
    try {
      await _firestore.collection('master_spesialisasi').doc(id).update({
        'status': 'Dihapus',
        'diubahPada': FieldValue.serverTimestamp(),
      });
      await fetchSpesialisasi();
      Get.snackbar('Berhasil', 'Spesialisasi berhasil dihapus.');
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus data: ${e.toString()}');
    }
  }
}
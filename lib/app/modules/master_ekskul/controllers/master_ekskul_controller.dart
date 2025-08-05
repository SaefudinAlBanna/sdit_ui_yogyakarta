// File: lib/app/modules/admin_manajemen/controllers/master_ekskul_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../models/master_ekskul_model.dart';

class MasterEkskulController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  
  // State List
  final RxBool isLoading = false.obs;
  final RxList<MasterEkskulModel> daftarMasterEkskul = <MasterEkskulModel>[].obs;

  // State Form
  final TextEditingController namaC = TextEditingController();
  final TextEditingController kategoriC = TextEditingController();
  final TextEditingController deskripsiC = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchMasterEkskul();
  }

  Future<void> fetchMasterEkskul() async {
    try {
      isLoading.value = true;
      final snapshot = await _firestore
          .collection('master_ekskul')
          .where('status', isEqualTo: 'Aktif')
          .orderBy('namaMaster')
          .get();
      daftarMasterEkskul.value = snapshot.docs.map((doc) => MasterEkskulModel.fromFirestore(doc)).toList();
    } catch (e) {
      print(e);
      Get.snackbar('Error', 'Gagal memuat data master ekskul: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addMasterEkskul() async {
    if (namaC.text.isEmpty || kategoriC.text.isEmpty) {
      Get.snackbar('Peringatan', 'Nama dan Kategori wajib diisi.');
      return;
    }

    try {
      isLoading.value = true;
      final newId = _uuid.v4();
      final now = Timestamp.now();
      final newEkskul = MasterEkskulModel(
        id: newId,
        namaMaster: namaC.text,
        kategori: kategoriC.text,
        deskripsiDefault: deskripsiC.text,
        status: 'Aktif',
        dibuatPada: now,
        diubahPada: now,
      );

      await _firestore.collection('master_ekskul').doc(newId).set(newEkskul.toFirestore());
      
      Get.back(); // Tutup dialog
      await fetchMasterEkskul();
      Get.snackbar('Berhasil', 'Master Ekskul berhasil ditambahkan.');
    } catch (e) {
      Get.snackbar('Error', 'Gagal menambah data: $e');
    } finally {
      isLoading.value = false;
      clearForm();
    }
  }

  Future<void> updateMasterEkskul(String id) async {
    if (namaC.text.isEmpty || kategoriC.text.isEmpty) {
      Get.snackbar('Peringatan', 'Nama dan Kategori wajib diisi.');
      return;
    }
    
    try {
       isLoading.value = true;
       await _firestore.collection('master_ekskul').doc(id).update({
        'namaMaster': namaC.text,
        'kategori': kategoriC.text,
        'deskripsiDefault': deskripsiC.text,
        'diubahPada': FieldValue.serverTimestamp(),
       });
       Get.back(); // Tutup dialog
       await fetchMasterEkskul();
       Get.snackbar('Berhasil', 'Master Ekskul berhasil diperbarui.');
    } catch(e) {
       Get.snackbar('Error', 'Gagal memperbarui data: $e');
    } finally {
       isLoading.value = false;
       clearForm();
    }
  }

  Future<void> deleteMasterEkskul(String id) async {
    try {
      await _firestore.collection('master_ekskul').doc(id).update({
        'status': 'Dihapus',
        'diubahPada': FieldValue.serverTimestamp(),
      });
      await fetchMasterEkskul();
      Get.snackbar('Berhasil', 'Master Ekskul berhasil dihapus.');
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus data: $e');
    }
  }

  void clearForm() {
    namaC.clear();
    kategoriC.clear();
    deskripsiC.clear();
  }

  void fillFormForEdit(MasterEkskulModel ekskul) {
    namaC.text = ekskul.namaMaster;
    kategoriC.text = ekskul.kategori;
    deskripsiC.text = ekskul.deskripsiDefault;
  }
}
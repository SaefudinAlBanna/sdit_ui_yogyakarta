// lib/app/modules/manajemen_jabatan/controllers/manajemen_jabatan_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../modules/home/controllers/home_controller.dart';

class ManajemenJabatanController extends GetxController {
  // --- DEPENDENSI & STATE ---
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();
  final RxBool isLoading = true.obs;
  final RxList<DocumentSnapshot> daftarJabatan = RxList<DocumentSnapshot>();
  final TextEditingController jabatanC = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchJabatan();
  }

  @override
  void onClose() {
    jabatanC.dispose();
    super.onClose();
  }

  // --- LOGIKA CRUD ---
  Future<void> fetchJabatan() async {
    isLoading.value = true;
    try {
      final snapshot = await firestore
          .collection('Sekolah')
          .doc(homeC.idSekolah)
          .collection('jabatan') // Koleksi untuk Jabatan
          .orderBy('nama')
          .get();
      daftarJabatan.assignAll(snapshot.docs);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data jabatan: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _performFirestoreOperation(Future<void> Function() operation, String successMessage) async {
    try {
      await operation();
      Get.back(); // Tutup dialog
      Get.snackbar('Berhasil', successMessage);
      fetchJabatan(); // Muat ulang daftar
      jabatanC.clear();
    } catch (e) {
      Get.snackbar('Error', 'Operasi gagal: $e');
    }
  }

  void tambahJabatan() {
    if (jabatanC.text.trim().isEmpty) return;
    _performFirestoreOperation(
      () => firestore.collection('Sekolah').doc(homeC.idSekolah).collection('jabatan').add({'nama': jabatanC.text.trim()}),
      'Jabatan baru berhasil ditambahkan.'
    );
  }

  void editJabatan(String docId) {
    if (jabatanC.text.trim().isEmpty) return;
    _performFirestoreOperation(
      () => firestore.collection('Sekolah').doc(homeC.idSekolah).collection('jabatan').doc(docId).update({'nama': jabatanC.text.trim()}),
      'Jabatan berhasil diperbarui.'
    );
  }

  void hapusJabatan(String docId, String namaJabatan) {
    Get.defaultDialog(
      title: 'Konfirmasi Hapus',
      middleText: 'Anda yakin ingin menghapus jabatan "$namaJabatan"?',
      actions: [
        OutlinedButton(onPressed: () => Get.back(), child: Text('Batal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => _performFirestoreOperation(
            () => firestore.collection('Sekolah').doc(homeC.idSekolah).collection('jabatan').doc(docId).delete(),
            'Jabatan "$namaJabatan" telah dihapus.'
          ),
          child: Text('Hapus', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  void showFormDialog({String? docId, String? namaAwal}) {
    jabatanC.text = docId != null ? namaAwal ?? '' : '';
    Get.defaultDialog(
      title: docId == null ? 'Tambah Jabatan Baru' : 'Edit Jabatan',
      content: TextField(controller: jabatanC, autofocus: true, decoration: InputDecoration(labelText: 'Nama Jabatan')),
      actions: [
        OutlinedButton(onPressed: () => Get.back(), child: Text('Batal')),
        ElevatedButton(onPressed: () => docId == null ? tambahJabatan() : editJabatan(docId), child: Text('Simpan')),
      ],
    );
  }
}
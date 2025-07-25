// lib/app/modules/manajemen_tugas/controllers/manajemen_tugas_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../modules/home/controllers/home_controller.dart';

class ManajemenTugasController extends GetxController {
  // --- DEPENDENSI & STATE ---
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();
  final RxBool isLoading = true.obs;
  final RxList<DocumentSnapshot> daftarTugas = RxList<DocumentSnapshot>();
  final TextEditingController tugas_tambahanC = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchTugas();
  }

  @override
  void onClose() {
    tugas_tambahanC.dispose();
    super.onClose();
  }

  // --- LOGIKA CRUD ---
  Future<void> fetchTugas() async {
    isLoading.value = true;
    try {
      final snapshot = await firestore
          .collection('Sekolah')
          .doc(homeC.idSekolah)
          .collection('tugas_tambahan') // Koleksi untuk tugas_tambahan
          .orderBy('nama')
          .get();
      daftarTugas.assignAll(snapshot.docs);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data Tugas: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _performFirestoreOperation(Future<void> Function() operation, String successMessage) async {
    try {
      await operation();
      Get.back(); // Tutup dialog
      Get.snackbar('Berhasil', successMessage);
      fetchTugas(); // Muat ulang daftar
      tugas_tambahanC.clear();
    } catch (e) {
      Get.snackbar('Error', 'Operasi gagal: $e');
    }
  }

  void tambahTugas() {
    if (tugas_tambahanC.text.trim().isEmpty) return;
    _performFirestoreOperation(
      () => firestore.collection('Sekolah').doc(homeC.idSekolah).collection('tugas_tambahan').add({'nama': tugas_tambahanC.text.trim()}),
      'Tugas baru berhasil ditambahkan.'
    );
  }

  void editTugas(String docId) {
    if (tugas_tambahanC.text.trim().isEmpty) return;
    _performFirestoreOperation(
      () => firestore.collection('Sekolah').doc(homeC.idSekolah).collection('tugas_tambahan').doc(docId).update({'nama': tugas_tambahanC.text.trim()}),
      'Tugas berhasil diperbarui.'
    );
  }

  void hapusTugas(String docId, String namaTugas) {
    Get.defaultDialog(
      title: 'Konfirmasi Hapus',
      middleText: 'Anda yakin ingin menghapus tugas tamabahan "$namaTugas"?',
      actions: [
        OutlinedButton(onPressed: () => Get.back(), child: Text('Batal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => _performFirestoreOperation(
            () => firestore.collection('Sekolah').doc(homeC.idSekolah).collection('tugas_tambahan').doc(docId).delete(),
            'Tugas "$namaTugas" telah dihapus.'
          ),
          child: Text('Hapus', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  void showFormDialog({String? docId, String? namaAwal}) {
    tugas_tambahanC.text = docId != null ? namaAwal ?? '' : '';
    Get.defaultDialog(
      title: docId == null ? 'Tambah Tugas Baru' : 'Edit Tugas',
      content: TextField(controller: tugas_tambahanC, autofocus: true, decoration: InputDecoration(labelText: 'Nama Tugas')),
      actions: [
        OutlinedButton(onPressed: () => Get.back(), child: Text('Batal')),
        ElevatedButton(onPressed: () => docId == null ? tambahTugas() : editTugas(docId), child: Text('Simpan')),
      ],
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/spesialisasi_model.dart';
import 'package:uuid/uuid.dart';
import '../../../models/pembina_eksternal_model.dart';

class PembinaEksternalController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // State untuk List
  final RxBool isLoading = false.obs;
  final RxList<PembinaEksternalModel> daftarPembina = <PembinaEksternalModel>[].obs;
  final RxString statusFilter = 'Aktif'.obs;

  final RxString searchQuery = ''.obs;

  // State untuk Form
  final TextEditingController namaC = TextEditingController();
  final TextEditingController kontakC = TextEditingController();
  final RxList<SpesialisasiModel> opsiSpesialisasi = <SpesialisasiModel>[].obs;
  final RxList<dynamic> selectedSpesialisasi = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Panggil keduanya saat inisialisasi
    fetchPembina();
    fetchSpesialisasiOptions();
  }

  void changeStatusFilter(String newStatus) {
    statusFilter.value = newStatus;
    searchQuery.value = '';
    fetchPembina();
  }

  Future<void> fetchPembina() async {
    try {
      isLoading.value = true;
      final snapshot = await _firestore
          .collection('pembina_eksternal')
          // Menggunakan filter dari state
          .where('status', isEqualTo: statusFilter.value)
          .orderBy('namaLengkap')
          .get();
      daftarPembina.value = snapshot.docs.map((doc) => PembinaEksternalModel.fromFirestore(doc)).toList();
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data pembina: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSpesialisasiOptions() async {
    try {
      final snapshot = await _firestore
          .collection('master_spesialisasi')
          .where('status', isEqualTo: 'Aktif')
          .get();
      opsiSpesialisasi.value = snapshot.docs.map((doc) => SpesialisasiModel.fromFirestore(doc)).toList();
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat opsi spesialisasi: $e');
    }
  }
  
  Future<void> addPembina() async {
    if (namaC.text.isEmpty || kontakC.text.isEmpty) {
      Get.snackbar('Peringatan', 'Nama dan Kontak wajib diisi.');
      return;
    }

    try {
      isLoading.value = true;
      final newId = _uuid.v4();
      final newPembina = PembinaEksternalModel(
        id: newId,
        namaLengkap: namaC.text,
        kontak: kontakC.text,
        spesialisasiRefs: selectedSpesialisasi.map((e) => (e as SpesialisasiModel).id).toList(),
        status: 'Aktif',
        ekskulYangDiampu: [], // Defaultnya kosong saat dibuat
        dibuatPada: Timestamp.now(),
      );

      await _firestore.collection('pembina_eksternal').doc(newId).set(newPembina.toFirestore());
      
      Get.back(); // Tutup dialog/form
      await fetchPembina();
      Get.snackbar('Berhasil', 'Pembina Eksternal berhasil ditambahkan.');
    } catch (e) {
      Get.snackbar('Error', 'Gagal menambah pembina: $e');
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> updatePembina(String id) async {
    if (namaC.text.isEmpty || kontakC.text.isEmpty) {
      Get.snackbar('Peringatan', 'Nama dan Kontak wajib diisi.');
      return;
    }
    
    try {
      isLoading.value = true;
      final List<String> spesialisasiIds = selectedSpesialisasi.map((e) => (e as SpesialisasiModel).id).toList();

      await _firestore.collection('pembina_eksternal').doc(id).update({
        'namaLengkap': namaC.text,
        'kontak': kontakC.text,
        'spesialisasiRefs': spesialisasiIds,
        'diubahPada': FieldValue.serverTimestamp(), // Menambah jejak audit
      });

      Get.back(); // Tutup dialog
      await fetchPembina();
      Get.snackbar('Berhasil', 'Data Pembina berhasil diperbarui.');
    } catch (e) {
       Get.snackbar('Error', 'Gagal memperbarui data: $e');
    } finally {
       isLoading.value = false;
    }
  }
  
  // Nanti kita akan buat fungsi update dan delete juga
  Future<void> softDeletePembina(String id) async {
     try {
      await _firestore.collection('pembina_eksternal').doc(id).update({
        'status': 'Non-Aktif',
      });
      await fetchPembina();
      Get.snackbar('Berhasil', 'Pembina telah dinonaktifkan.');
    } catch (e) {
      Get.snackbar('Error', 'Gagal menonaktifkan pembina: $e');
    }
  }

  Future<void> reactivatePembina(String id) async {
    try {
      await _firestore.collection('pembina_eksternal').doc(id).update({
        'status': 'Aktif',
        'diubahPada': FieldValue.serverTimestamp(),
      });
      await fetchPembina();
      Get.snackbar('Berhasil', 'Pembina telah diaktifkan kembali.');
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengaktifkan pembina: $e');
    }
  }

  void clearForm() {
    namaC.clear();
    kontakC.clear();
    selectedSpesialisasi.clear();
  }

  void fillFormForEdit(PembinaEksternalModel pembina) {
    namaC.text = pembina.namaLengkap;
    kontakC.text = pembina.kontak;
    // Cari objek SpesialisasiModel lengkap berdasarkan Ref ID
    selectedSpesialisasi.value = opsiSpesialisasi
        .where((opsi) => pembina.spesialisasiRefs.contains(opsi.id))
        .toList();
  }
}
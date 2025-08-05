import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math'; // Diperlukan untuk string acak

class KurikulumMasterController extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final RxBool isLoading = false.obs;
  
  final RxList<Map<String, dynamic>> daftarMapel = <Map<String, dynamic>>[].obs;
  final Rxn<String> faseTerpilih = Rxn<String>();

  final List<String> daftarFase = ['fase_a', 'fase_b', 'fase_c'];

  final TextEditingController namaMapelC = TextEditingController();
  final TextEditingController singkatanMapelC = TextEditingController();

  // [BARU] Fungsi privat untuk membuat ID unik yang semi-readable
  String _generateIdMapel(String nama) {
    String safeName = nama.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    if (safeName.length > 20) {
      safeName = safeName.substring(0, 20);
    }
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final randomStr = String.fromCharCodes(Iterable.generate(
        5, (_) => chars.codeUnitAt(Random().nextInt(chars.length))));
    return '${safeName}_$randomStr';
  }

   Future<void> pilihFase(String fase) async {
      if (faseTerpilih.value == fase) return;
      faseTerpilih.value = fase;
      isLoading.value = true;
      try {
        final doc = await firestore.collection('konfigurasi_kurikulum').doc(fase).get();
        if (doc.exists && doc.data()?['matapelajaran'] != null) {
          final List<dynamic> mapelDariDB = doc.data()!['matapelajaran'];
          // Konversi ke List<Map<String, dynamic>>
          daftarMapel.assignAll(mapelDariDB.map((e) => e as Map<String, dynamic>).toList());
        } else {
          // Jika dokumen atau field belum ada, kosongkan list
          daftarMapel.clear();
        }
      } catch (e) {
        Get.snackbar('Error', 'Gagal memuat data kurikulum: $e');
      } finally {
        isLoading.value = false;
      }
   }
  
  // [DIROMBAK] tambahMapel sekarang membuat idMapel
  Future<void> tambahMapel() async {
    if (faseTerpilih.value == null || namaMapelC.text.isEmpty) {
      Get.snackbar('Gagal', 'Nama mapel tidak boleh kosong.'); return;
    }
    isLoading.value = true;
    try {
      final newMapel = {
        'idMapel': _generateIdMapel(namaMapelC.text), // <-- ID DIBUAT DI SINI
        'nama': namaMapelC.text,
        'singkatan': singkatanMapelC.text,
      };
      
      final docRef = firestore.collection('konfigurasi_kurikulum').doc(faseTerpilih.value!);
      await docRef.set({
        'matapelajaran': FieldValue.arrayUnion([newMapel])
      }, SetOptions(merge: true));
      
      daftarMapel.add(newMapel);
      Get.back();
      Get.snackbar('Berhasil', 'Mata pelajaran berhasil ditambahkan.');
    } catch (e) {
      Get.snackbar('Error', 'Gagal menambahkan mapel: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // [DIROMBAK] editMapel sekarang "menyembuhkan" data lama
  Future<void> editMapel(Map<String, dynamic> mapelLama) async {
    if (faseTerpilih.value == null || namaMapelC.text.isEmpty) return;
    isLoading.value = true;
    try {
      final mapelBaru = {
        // Jika mapel lama belum punya ID, buatkan yang baru. Jika sudah, gunakan yang lama.
        'idMapel': mapelLama['idMapel'] ?? _generateIdMapel(namaMapelC.text),
        'nama': namaMapelC.text,
        'singkatan': singkatanMapelC.text,
      };
      
      final docRef = firestore.collection('konfigurasi_kurikulum').doc(faseTerpilih.value!);
      WriteBatch batch = firestore.batch();
      
      batch.update(docRef, {'matapelajaran': FieldValue.arrayRemove([mapelLama])});
      batch.update(docRef, {'matapelajaran': FieldValue.arrayUnion([mapelBaru])});
      await batch.commit();

      final index = daftarMapel.indexOf(mapelLama);
      if (index != -1) {
        daftarMapel[index] = mapelBaru;
      }
      
      Get.back();
      Get.snackbar('Berhasil', 'Mata pelajaran berhasil diperbarui.');
    } catch (e) {
      Get.snackbar('Error', 'Gagal memperbarui mapel: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
    Future<void> hapusMapel(Map<String, dynamic> mapel) async {
    if (faseTerpilih.value == null) return;
    isLoading.value = true;
    try {
      final docRef = firestore.collection('konfigurasi_kurikulum').doc(faseTerpilih.value!);
      // `FieldValue.arrayRemove` akan menghapus mapel dari array
      await docRef.update({
        'matapelajaran': FieldValue.arrayRemove([mapel])
      });
      daftarMapel.remove(mapel); // Update UI
      Get.back(); // Tutup dialog konfirmasi
      Get.snackbar('Berhasil', 'Mata pelajaran berhasil dihapus.');
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus mapel: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
    @override
  void onClose() {
    namaMapelC.dispose();
    singkatanMapelC.dispose();
    super.onClose();
  }
}
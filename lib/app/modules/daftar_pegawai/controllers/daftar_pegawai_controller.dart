// lib/app/modules/daftar_pegawai/controllers/daftar_pegawai_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../modules/home/controllers/home_controller.dart';

class DaftarPegawaiController extends GetxController {
  // --- DEPENDENSI ---
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final HomeController homeC = Get.find<HomeController>();

  // --- STATE ---
  final RxBool isLoading = true.obs;
  // Kita simpan sebagai DocumentSnapshot agar punya akses ke ID dan data mentah
  final RxList<DocumentSnapshot> daftarPegawai = RxList<DocumentSnapshot>();
  final RxList<DocumentSnapshot> _semuaPegawai = RxList<DocumentSnapshot>();
  final RxList<DocumentSnapshot> daftarPegawaiFiltered = RxList<DocumentSnapshot>();

  final TextEditingController searchC = TextEditingController();
  final RxString searchQuery = "".obs;

  late TextEditingController adminPassC;

  @override
  void onInit() {
    super.onInit();
    adminPassC = TextEditingController();
    fetchPegawai();
    ever(searchQuery, (_) => _filterData());
  }

  @override
  void onClose() {
    adminPassC.dispose();
    super.onClose();
  }

  /// Mengambil semua data pegawai dari Firestore.
  Future<void> fetchPegawai() async {
    isLoading.value = true;
    try {
      final snapshot = await firestore
          .collection('Sekolah')
          .doc(homeC.idSekolah)
          .collection('pegawai')
          .orderBy('nama') // Urutkan berdasarkan nama
          .get();
      // daftarPegawai.assignAll(snapshot.docs);
      _semuaPegawai.assignAll(snapshot.docs);
      daftarPegawaiFiltered.assignAll(_semuaPegawai);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat daftar pegawai: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _filterData() {
    String query = searchQuery.value.toLowerCase();
    if (query.isEmpty) {
      daftarPegawaiFiltered.assignAll(_semuaPegawai);
    } else {
      var filtered = _semuaPegawai.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final String nama = (data['nama'] ?? '').toLowerCase();
        final String role = (data['role'] ?? '').toLowerCase();
        final List tugasList = data['tugas'] ?? [];
        final String tugas = tugasList.join(', ').toLowerCase();

        return nama.contains(query) || role.contains(query) || tugas.contains(query);
      }).toList();
      daftarPegawaiFiltered.assignAll(filtered);
    }
  }

  /// Menghapus pegawai dari Firestore.
  void hapusPegawai(String docId, String namaPegawai) {
    Get.defaultDialog(
      title: 'Hapus Pegawai',
      middleText: 'Anda yakin ingin menghapus "$namaPegawai"?\n\nUntuk keamanan, masukkan password Admin Anda.',
      content: Padding(
        padding: const EdgeInsets.only(top: 15.0, left: 8.0, right: 8.0),
        child: TextField(
          controller: adminPassC,
          obscureText: true,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: 'Password Admin',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: () { adminPassC.clear(); Get.back(); }, child: Text('Batal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => _performDeletion(docId, namaPegawai),
          child: Text('Hapus Permanen', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _performDeletion(String docId, String namaPegawai) async {
    if (adminPassC.text.isEmpty) {
      Get.snackbar('Error', 'Password Admin tidak boleh kosong.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    Get.dialog(Center(child: CircularProgressIndicator()), barrierDismissible: false);

    try {
      final user = auth.currentUser;
      if (user == null || user.email == null) throw Exception("Sesi Admin tidak valid.");

      // Langkah 1: Re-autentikasi Admin
      AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: adminPassC.text);
      await user.reauthenticateWithCredential(credential);

      // Langkah 2: Hapus dokumen dari Firestore
      await firestore
        .collection('Sekolah').doc(homeC.idSekolah)
        .collection('pegawai').doc(docId).delete();

      // Langkah 3 (yang kita bahas): Menghapus user dari Auth via Cloud Function akan terjadi otomatis di backend.

      Get.back(); // Tutup dialog loading
      Get.back(); // Tutup dialog konfirmasi
      adminPassC.clear();
      Get.snackbar('Berhasil', 'Data pegawai "$namaPegawai" telah dihapus dari database.');
      fetchPegawai();

    } on FirebaseAuthException catch (e) {
      Get.back();
      String message = 'Terjadi kesalahan otentikasi.';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Password Admin yang Anda masukkan salah.';
      } else if (e.code == 'too-many-requests') {
        message = 'Terlalu banyak percobaan. Coba lagi nanti.';
      }
      Get.snackbar('Gagal', message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.back();
      Get.snackbar('Gagal', 'Terjadi kesalahan sistem: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    }
  }
}


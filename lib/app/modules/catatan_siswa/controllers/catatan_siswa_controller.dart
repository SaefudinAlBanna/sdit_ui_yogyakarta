// lib/app/modules/catatan_siswa/controllers/catatan_siswa_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CatatanSiswaController extends GetxController {
  // --- Firebase & User Info ---
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late final String idUser;
  late final String emailAdmin;
  final String idSekolah = "20404148";
  String? idTahunAjaran;

  // --- State untuk UI ---
  final RxBool isLoading = true.obs;
  final RxString selectedKelasId = ''.obs;
  final RxString selectedSiswaId = ''.obs;

  final RxList<Map<String, String>> daftarKelas = <Map<String, String>>[].obs;
  final RxList<Map<String, String>> daftarSiswa = <Map<String, String>>[].obs;
  
  // --- Text Controllers untuk Dialog ---
  final TextEditingController judulC = TextEditingController();
  final TextEditingController catatanC = TextEditingController();
  final TextEditingController tindakanC = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }
  
  Future<void> _initialize() async {
    idUser = auth.currentUser!.uid;
    emailAdmin = auth.currentUser!.email!;
    final tahunAjaran = await _getTahunAjaranTerakhir();
    idTahunAjaran = tahunAjaran.replaceAll("/", "-");
    await fetchDaftarKelas();
    isLoading.value = false;
  }

  Future<String> _getTahunAjaranTerakhir() async {
    final snapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').orderBy('namatahunajaran', descending: true).limit(1).get();
    if (snapshot.docs.isEmpty) return "TA-Tidak-Ditemukan";
    return snapshot.docs.first.data()['namatahunajaran'] as String;
  }

  Future<void> fetchDaftarKelas() async {
    if (idTahunAjaran == null) return;
    final snapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran!).collection('kelastahunajaran').get();
    final kelas = snapshot.docs.map((doc) => {'id': doc.id, 'nama': doc.id}).toList();
    daftarKelas.assignAll(kelas);
  }

  void onKelasChanged(String? kelasId) async {
    if (kelasId == null || kelasId.isEmpty) return;
    selectedKelasId.value = kelasId;
    selectedSiswaId.value = ''; // Reset pilihan siswa
    daftarSiswa.clear();

    final snapshot = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran!).collection('kelastahunajaran').doc(kelasId).collection('daftarsiswa').get();
    final siswa = snapshot.docs.map((doc) => {'id': doc.id, 'nama': doc.data()['namasiswa'] as String}).toList();
    daftarSiswa.assignAll(siswa);
  }

  void onSiswaChanged(String? siswaId) {
    if (siswaId == null || siswaId.isEmpty) return;
    selectedSiswaId.value = siswaId;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCatatanSiswa() {
    if (selectedSiswaId.value.isEmpty || idTahunAjaran == null) {
      return const Stream.empty();
    }
    // Path ini mengarah ke catatan yang disimpan di bawah koleksi siswa
    return firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('siswa').doc(selectedSiswaId.value)
        .collection('tahunajaran').doc(idTahunAjaran!)
        .collection('catatansiswa').orderBy('tanggalinput', descending: true)
        .snapshots();
  }

  void openAddCatatanDialog() {
    if (selectedSiswaId.value.isEmpty) {
      Get.snackbar("Peringatan", "Silakan pilih kelas dan siswa terlebih dahulu.", backgroundColor: Colors.orange);
      return;
    }
    Get.dialog(
      AlertDialog(
        title: const Text("Buat Catatan Baru"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: judulC, decoration: const InputDecoration(labelText: 'Judul Catatan')),
              const SizedBox(height: 8),
              TextField(controller: catatanC, decoration: const InputDecoration(labelText: 'Isi Catatan'), maxLines: 4),
              const SizedBox(height: 8),
              TextField(controller: tindakanC, decoration: const InputDecoration(labelText: 'Tindakan Awal Guru BK')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text("Batal")),
          ElevatedButton(onPressed: _simpanCatatan, child: const Text("Simpan")),
        ],
      ),
    );
  }

  Future<void> _simpanCatatan() async {
    // Validasi input
    if (judulC.text.isEmpty || catatanC.text.isEmpty || tindakanC.text.isEmpty) {
      Get.snackbar("Error", "Semua field harus diisi.", backgroundColor: Colors.red);
      return;
    }

    try {
      // Ambil data penting yang dibutuhkan
      final siswaDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('siswa').doc(selectedSiswaId.value).get();
      final idWaliKelas = siswaDoc.data()?['idwalikelas'];

      final guruDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idUser).get();
      final namaGuru = guruDoc.data()?['alias'];
      
      if (idWaliKelas == null || namaGuru == null) {
        throw Exception("Data wali kelas atau guru tidak ditemukan.");
      }

      final docIdCatatan = firestore.collection("id").doc().id; // ID unik
      final now = DateTime.now();

      final dataCatatan = {
        'idpenginput': idUser,
        'namapenginput': namaGuru,
        'idwalikelas': idWaliKelas,
        'nisn': selectedSiswaId.value,
        'namasiswa': daftarSiswa.firstWhere((s) => s['id'] == selectedSiswaId.value)['nama'],
        'kelassiswa': selectedKelasId.value,
        'judulinformasi': judulC.text,
        'informasicatatansiswa': catatanC.text,
        'tindakangurubk': tindakanC.text,
        'tanggapanwalikelas': "",
        'tanggapankepalasekolah': "",
        'tanggapanorangtua': "",
        'tanggalinput': now.toIso8601String(),
        'docId': docIdCatatan,
      };

      // Simpan catatan ke semua pihak yang relevan menggunakan WriteBatch
      WriteBatch batch = firestore.batch();

      // Path untuk siswa
      final siswaPath = firestore.collection('Sekolah').doc(idSekolah).collection('siswa').doc(selectedSiswaId.value).collection('tahunajaran').doc(idTahunAjaran!).collection('catatansiswa').doc(docIdCatatan);
      batch.set(siswaPath, dataCatatan);
      
      // Path untuk Guru BK (diri sendiri)
      final guruBkPath = firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idUser).collection('catatansiswabk').doc(docIdCatatan);
      batch.set(guruBkPath, dataCatatan);

      // Path untuk Wali Kelas
      final waliKelasPath = firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idWaliKelas).collection('catatansiswawali').doc(docIdCatatan);
      batch.set(waliKelasPath, dataCatatan);
      
      // Commit batch
      await batch.commit();

      Get.back(); // Tutup dialog
      Get.snackbar("Sukses", "Catatan berhasil disimpan.", backgroundColor: Colors.green);
      _clearForm();
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan catatan: ${e.toString()}", backgroundColor: Colors.red);
    }
  }

  void _clearForm() {
    judulC.clear();
    catatanC.clear();
    tindakanC.clear();
  }
}
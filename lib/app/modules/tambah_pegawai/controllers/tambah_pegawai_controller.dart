// lib/app/modules/tambah_pegawai/controllers/tambah_pegawai_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../home/controllers/home_controller.dart';

class TambahPegawaiController extends GetxController {
  // --- DEPENDENSI & KUNCI ---
  final formKey = GlobalKey<FormState>();
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final homeC = Get.find<HomeController>();

  // --- FORM CONTROLLERS ---
  late TextEditingController namaC;
  late TextEditingController emailC;
  late TextEditingController passAdminC;

  // --- STATE LOADING ---
  final RxBool isLoadingProses = false.obs; // Untuk proses simpan utama
  final RxBool isJabatanLoading = true.obs;
  final RxBool isTugasLoading = true.obs;

  // --- STATE DATA MASTER & DATA TERPILIH ---
  final RxString jenisKelamin = "".obs;
  
  // Untuk Jabatan (Single Choice)
  final RxList<String> semuaJabatan = <String>[].obs;
  final Rxn<String> jabatanTerpilih = Rxn<String>();

  // Untuk Tugas Tambahan (Multi Choice)
  final RxList<String> semuaTugas = <String>[].obs;
  final RxList<String> tugasTerpilih = <String>[].obs;

  String? docId;
  bool get isEditMode => docId != null;

  @override
  void onInit() {
    super.onInit();
    namaC = TextEditingController();
    emailC = TextEditingController();
    passAdminC = TextEditingController();
    
    if (Get.arguments != null) {
      docId = Get.arguments['id'] as String;
      final data = Get.arguments['data'] as Map<String, dynamic>;

      // Isi semua field form dengan data yang ada
      namaC.text = data['nama'] ?? '';
      emailC.text = data['email'] ?? '';
      jenisKelamin.value = data['jeniskelamin'] ?? '';
      jabatanTerpilih.value = data['role'];
      
      final tugasData = data['tugas'];
      if (tugasData is List) {
        tugasTerpilih.assignAll(List<String>.from(tugasData));
      }
    }
    
    _muatSemuaJabatan();
    _muatSemuaTugas();
  }

  @override
  void onClose() {
    namaC.dispose();
    emailC.dispose();
    passAdminC.dispose();
    super.onClose();
  }
  
  // --- FUNGSI HELPER ---
  void onChangeJenisKelamin(String? value) => jenisKelamin.value = value ?? "";
  void onJabatanSelected(String? value) => jabatanTerpilih.value = value;
  void onTugasSelected(List<String> values) => tugasTerpilih.assignAll(values);

  // --- LOGIKA PENGAMBILAN DATA ---
  Future<void> _muatSemuaJabatan() async {
    isJabatanLoading.value = true;
    try {
      final snapshot = await firestore.collection('Sekolah').doc(homeC.idSekolah).collection('jabatan').get();
      semuaJabatan.assignAll(snapshot.docs.map((doc) => doc['nama'] as String).toList());
    } finally {
      isJabatanLoading.value = false;
    }
  }

  Future<void> _muatSemuaTugas() async {
    isTugasLoading.value = true;
    try {
      final snapshot = await firestore.collection('Sekolah').doc(homeC.idSekolah).collection('tugas_tambahan').get();
      semuaTugas.assignAll(snapshot.docs.map((doc) => doc['nama'] as String).toList());
    } finally {
      isTugasLoading.value = false;
    }
  }

  // --- LOGIKA UTAMA: SIMPAN DATA ---
  Future<void> _prosesSimpanData() async {
    final String? emailAdmin = auth.currentUser?.email;
    if (emailAdmin == null) {
      Get.snackbar("Error", "Sesi admin tidak valid.");
      return;
    }

    isLoadingProses.value = true;
    try {
      final dataToSave = {
        'nama': namaC.text.trim(),
        'jeniskelamin': jenisKelamin.value,
        'alias': "${jenisKelamin.value == "Laki-Laki" ? "Ustadz" : "Ustazah"} ${namaC.text.trim()}",
        'role': jabatanTerpilih.value,
        'tugas': tugasTerpilih.toList(),
      };

      if (isEditMode) {
        // --- LOGIKA UNTUK MODE EDIT ---
        await firestore.collection("Sekolah").doc(homeC.idSekolah).collection('pegawai').doc(docId!).update(dataToSave);
        Get.back(result: true); // Kembali & kirim sinyal sukses
        Get.snackbar('Berhasil', 'Data pegawai berhasil diperbarui.');

      } else {
        // --- LOGIKA UNTUK MODE TAMBAH (YANG SUDAH ADA) ---
        await auth.signInWithEmailAndPassword(email: emailAdmin, password: passAdminC.text);
        
        // Buat user di Auth HANYA jika mode tambah
        UserCredential pegawaiCredential = await auth.createUserWithEmailAndPassword(email: emailC.text.trim(), password: 'sditui');
        await auth.signInWithEmailAndPassword(email: emailAdmin, password: passAdminC.text);

        String uid = pegawaiCredential.user!.uid;
        dataToSave['uid'] = uid;
        dataToSave['email'] = emailC.text.trim();
        dataToSave['createdAt'] = FieldValue.serverTimestamp();
        dataToSave['createdBy'] = emailAdmin;

        await firestore.collection("Sekolah").doc(homeC.idSekolah).collection('pegawai').doc(uid).set(dataToSave);
        await pegawaiCredential.user!.sendEmailVerification();
        Get.back(result: true); // Kembali & kirim sinyal sukses
        Get.snackbar('Berhasil', 'Pegawai baru berhasil ditambahkan.');
      }
    } on FirebaseAuthException catch (e) {
      Get.back();
      // ... (Error handling yang sudah ada sebelumnya sudah cukup baik)
      Get.snackbar('Error Otentikasi', e.message ?? 'Terjadi kesalahan');
    } catch (e) {
      Get.back();
      Get.snackbar('Error Sistem', e.toString());
    } finally {
      isLoadingProses.value = false;
      passAdminC.clear();
    }
  }

  void validasiDanSimpan() {
    if (!formKey.currentState!.validate()) return;
    
    // Untuk mode Edit, kita tidak perlu verifikasi password lagi, bisa langsung simpan
    if (isEditMode) {
      _prosesSimpanData();
    } else {
      // Tampilkan dialog verifikasi HANYA untuk mode Tambah
      Get.defaultDialog(
        title: 'Verifikasi Admin',
      content: TextField(controller: passAdminC, obscureText: true, decoration: InputDecoration(labelText: 'Password Admin')),
      actions: [
        OutlinedButton(onPressed: () => Get.back(), child: Text('Batal')),
        Obx(() => ElevatedButton(
          onPressed: isLoadingProses.isTrue ? null : _prosesSimpanData,
          child: Text(isLoadingProses.isTrue ? 'MEMPROSES...' : 'KONFIRMASI'),
        )),
      ],
    );
    }
  }
}
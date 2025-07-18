// lib/app/modules/kelas_tahfidz/controllers/kelas_tahfidz_controller.dart

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../modules/home/controllers/home_controller.dart';

class KelasTahfidzController extends GetxController {
  // --- DEPENDENSI ---
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();
  final FirebaseAuth auth = FirebaseAuth.instance;

  // --- STATE UTAMA ---
  final RxBool isLoading = true.obs;
  final RxBool hasAccess = false.obs;
  final RxString idKelas = ''.obs;
  final RxString namaKelas = ''.obs;
  final RxString namaWaliKelas = ''.obs;
  final RxList<Map<String, dynamic>> daftarSiswa = <Map<String, dynamic>>[].obs;
  final RxMap<String, String> daftarPendamping = <String, String>{}.obs;

  // --- STATE UNTUK FORM & EDITING ---
  final formKey = GlobalKey<FormState>();
  late TextEditingController materiC;
  late TextEditingController nilaiC;
  late TextEditingController catatanGuruC;
  final RxString selectedKategori = 'Hafalan Baru'.obs;
  final Rxn<String> editingDocId = Rxn<String>(); // null = mode tambah, not-null = mode edit

  final RxBool isSaving = false.obs;
  Map<String, TextEditingController> nilaiMassalControllers = {};

  @override
  void onInit() {
    super.onInit();
    materiC = TextEditingController();
    nilaiC = TextEditingController();
    catatanGuruC = TextEditingController();
    loadDataBasedOnRole();
  }

  @override
  void onClose() {
    nilaiMassalControllers.forEach((_, controller) => controller.dispose());
    materiC.dispose();
    nilaiC.dispose();
    catatanGuruC.dispose();
    super.onClose();
  }

  Future<void> loadDataBasedOnRole() async {
    try {
      isLoading.value = true;
      daftarPendamping.clear();
      final userRole = homeC.userRole.value;

      if (userRole == 'Guru Kelas') {
        await _fetchWaliKelasData();
      } else {
        hasAccess.value = false;
      }
    } catch (e) {
      Get.snackbar("Terjadi Kesalahan", "Gagal memuat data: $e");
      hasAccess.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchWaliKelasData() async {
    final String idUser = auth.currentUser!.uid;
    final String idTahunAjaran = homeC.idTahunAjaran.value!;
    
    final querySnapshot = await firestore
        .collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('kelastahunajaran')
        .where('idwalikelas', isEqualTo: idUser).limit(1).get();

    if (querySnapshot.docs.isNotEmpty) {
      hasAccess.value = true;
      final kelasDoc = querySnapshot.docs.first;
      final kelasData = kelasDoc.data();

      idKelas.value = kelasDoc.id;
      namaKelas.value = kelasData['namakelas'] ?? 'Tanpa Nama';
      namaWaliKelas.value = kelasData['walikelas'] ?? 'Tanpa Nama';

      if (kelasData.containsKey('tahfidz_info') && kelasData['tahfidz_info']['pendamping'] != null) {
        final pendampingFromDB = Map<String, String>.from(kelasData['tahfidz_info']['pendamping']);
        daftarPendamping.assignAll(pendampingFromDB);
      }
      await _fetchSiswaInKelas(kelasDoc.id);
    } else {
      hasAccess.value = false;
    }
  }

  Future<void> _fetchSiswaInKelas(String idKelasParam) async {
    final String idTahunAjaran = homeC.idTahunAjaran.value!;
    final siswaSnapshot = await firestore.collection('Sekolah').doc(homeC.idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('kelastahunajaran').doc(idKelasParam).collection('daftarsiswa').get();
    // if (siswaSnapshot.docs.isNotEmpty) {
    //   daftarSiswa.assignAll(siswaSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());

    if (siswaSnapshot.docs.isNotEmpty) {
    final listSiswa = siswaSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    daftarSiswa.assignAll(listSiswa);

      // --- LOGIKA BARU ---
    // Buat controller untuk setiap siswa
    nilaiMassalControllers.clear();
    for (var siswa in listSiswa) {
      nilaiMassalControllers[siswa['id']] = TextEditingController();
    }
    // --- AKHIR LOGIKA BARU ---

    }
  }

  // --- FUNGSI BARU UNTUK SIMPAN NILAI MASSAL ---
Future<void> saveNilaiMassal(String kategori, String materi) async {
  // Validasi sederhana
  if (kategori.isEmpty || materi.isEmpty) {
    Get.snackbar("Peringatan", "Kategori dan Materi wajib diisi.");
    return;
  }

  Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
  try {
    WriteBatch batch = firestore.batch();
    int successCount = 0;

    // Iterasi melalui setiap controller nilai
    for (var entry in nilaiMassalControllers.entries) {
      String nisn = entry.key;
      String nilai = entry.value.text;

      // Hanya proses siswa yang nilainya diisi
      if (nilai.isNotEmpty) {
        final collectionRef = firestore
            .collection('Sekolah').doc(homeC.idSekolah)
            .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
            .collection('kelastahunajaran').doc(idKelas.value)
            .collection('daftarsiswa').doc(nisn)
            .collection('catatan_tahfidz');

        final dataToSave = {
          "tanggal_penilaian": Timestamp.now(),
          "kategori": kategori,
          "materi": materi,
          "nilai": int.tryParse(nilai) ?? 0,
          "catatan_guru": "Input massal.", // Catatan default
          "penilai_uid": auth.currentUser!.uid,
          "penilai_nama": homeC.userRole.value
        };

        // Tambahkan operasi ke batch
        batch.set(collectionRef.doc(), dataToSave);
        successCount++;
      }
    }

    if (successCount == 0) {
      Get.back();
      Get.snackbar("Info", "Tidak ada nilai yang diinputkan.");
      return;
    }

    await batch.commit(); // Jalankan semua operasi tulis
    Get.back();
    Get.snackbar("Berhasil", "$successCount data nilai berhasil disimpan.");
    
    // Kosongkan semua text field setelah berhasil
    nilaiMassalControllers.forEach((_, controller) => controller.clear());

  } catch (e) {
    Get.back();
    Get.snackbar("Gagal", "Terjadi kesalahan: $e");
  }
}

  // --- FUNGSI-FUNGSI BARU UNTUK MANAJEMEN PENDAMPING ---

  /// 1. Mengambil daftar guru 'Pengampu' yang tersedia.
  /// PERBAIKAN: Mengubah return type menjadi Future<List<Map<String, dynamic>>>
  Future<List<Map<String, dynamic>>> getAvailablePendamping() async {
    final snapshot = await firestore
        .collection('Sekolah').doc(homeC.idSekolah)
        .collection('pegawai')
        .where('role', isEqualTo: 'Pengampu')
        .where('tugas_pendamping_tahfidz', isNull: true)
        .get();

    return snapshot.docs.map((doc) => {
      'uid': doc.id,
      'nama': doc.data()['alias'] ?? 'Tanpa Nama',
    }).toList();
  }

  /// 2. Menambahkan seorang guru sebagai pendamping.
  Future<void> addPendamping(String uid, String nama) async {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      final String idTahunAjaran = homeC.idTahunAjaran.value!;
      final kelasRef = firestore.collection('Sekolah').doc(homeC.idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('kelastahunajaran').doc(idKelas.value);
      final guruRef = firestore.collection('Sekolah').doc(homeC.idSekolah).collection('pegawai').doc(uid);

      WriteBatch batch = firestore.batch();

      batch.set(kelasRef, {
        'tahfidz_info': {
          'pendamping': {uid: nama}
        }
      }, SetOptions(merge: true));

      batch.update(guruRef, {'tugas_pendamping_tahfidz': idKelas.value});

      await batch.commit();

      daftarPendamping[uid] = nama;
      Get.back();
      Get.snackbar("Berhasil", "$nama telah ditambahkan sebagai pendamping.");

    } catch (e) {
      Get.back();
      Get.snackbar("Gagal", "Gagal menambahkan pendamping: $e");
    }
  }

  /// 3. Menghapus seorang guru dari daftar pendamping.
  Future<void> removePendamping(String uid) async {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      final String idTahunAjaran = homeC.idTahunAjaran.value!;
      final kelasRef = firestore.collection('Sekolah').doc(homeC.idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('kelastahunajaran').doc(idKelas.value);
      final guruRef = firestore.collection('Sekolah').doc(homeC.idSekolah).collection('pegawai').doc(uid);

      WriteBatch batch = firestore.batch();

      batch.update(kelasRef, {'tahfidz_info.pendamping.$uid': FieldValue.delete()});
      batch.update(guruRef, {'tugas_pendamping_tahfidz': FieldValue.delete()});

      await batch.commit();
      
      daftarPendamping.remove(uid);
      Get.back();
      Get.snackbar("Berhasil", "Pendamping telah dihapus.");
    } catch (e) {
      Get.back();
      Get.snackbar("Gagal", "Gagal menghapus pendamping: $e");
    }
  }

  // --- FUNGSI-FUNGSI BARU UNTUK PENILAIAN ---

  /// Mengambil stream catatan tahfidz untuk siswa tertentu.
  Stream<QuerySnapshot<Map<String, dynamic>>> getCatatanTahfidzStream(String nisn) {
    return firestore
        .collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
        .collection('kelastahunajaran').doc(idKelas.value)
        .collection('daftarsiswa').doc(nisn)
        .collection('catatan_tahfidz')
        .orderBy('tanggal_penilaian', descending: true)
        .snapshots();
  }

  /// Memulai mode edit: mengisi form dengan data yang ada.
  void startEdit(Map<String, dynamic> catatan, String docId) {
    editingDocId.value = docId;
    selectedKategori.value = catatan['kategori'] ?? 'Hafalan Baru';
    materiC.text = catatan['materi'] ?? '';
    nilaiC.text = (catatan['nilai'] ?? 0).toString();
    catatanGuruC.text = catatan['catatan_guru'] ?? '';
  }

  /// Membersihkan form dan keluar dari mode edit.
  void clearForm() {
    editingDocId.value = null;
    materiC.clear();
    nilaiC.clear();
    catatanGuruC.clear();
    selectedKategori.value = 'Hafalan Baru';
    formKey.currentState?.reset();
  }

  /// Menyimpan (menambah atau mengupdate) catatan tahfidz.
  Future<void> saveCatatanTahfidz(String nisn) async {
    if (formKey.currentState!.validate()) {
    isSaving.value = true; // <-- Mulai loading
    try {
        final dataToSave = {
          "tanggal_penilaian": Timestamp.now(),
          "kategori": selectedKategori.value,
          "materi": materiC.text,
          "nilai": int.tryParse(nilaiC.text) ?? 0,
          "catatan_guru": catatanGuruC.text,
          "penilai_uid": auth.currentUser!.uid,
          "penilai_nama": homeC.userRole.value // Atau bisa ambil nama alias dari profil
        };
        
        final collectionRef = firestore
            .collection('Sekolah').doc(homeC.idSekolah)
            .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
            .collection('kelastahunajaran').doc(idKelas.value)
            .collection('daftarsiswa').doc(nisn)
            .collection('catatan_tahfidz');

        if (editingDocId.value == null) {
          // Mode Tambah Baru
          await collectionRef.add(dataToSave);
          Get.snackbar("Berhasil", "Catatan penilaian baru telah disimpan.");
        } else {
          // Mode Update
          await collectionRef.doc(editingDocId.value).update(dataToSave);
          Get.snackbar("Berhasil", "Catatan penilaian telah diperbarui.");
        }
        
        clearForm(); // Reset form setelah berhasil
        // Get.back(); // Tutup dialog loading

      } catch (e) {
      Get.snackbar("Gagal", "Gagal menyimpan data: $e");
    } finally {
      isSaving.value = false; // <-- Selalu berhenti loading, baik sukses maupun gagal
    }
  }
}

  /// Menghapus catatan tahfidz.
  Future<void> deleteCatatanTahfidz(String nisn, String docId) async {
     Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
     try {
       await firestore
           .collection('Sekolah').doc(homeC.idSekolah)
           .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
           .collection('kelastahunajaran').doc(idKelas.value)
           .collection('daftarsiswa').doc(nisn)
           .collection('catatan_tahfidz').doc(docId).delete();
      
      Get.back();
      Get.snackbar("Berhasil", "Catatan telah dihapus.");
     } catch (e) {
       Get.back();
       Get.snackbar("Gagal", "Gagal menghapus catatan: $e");
     }
  }

  /// Membuat dan mencetak PDF riwayat tahfidz siswa.
  Future<void> generateAndPrintPdf(String namaSiswa, List<QueryDocumentSnapshot<Map<String, dynamic>>> catatanList) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text("Laporan Riwayat Tahfidz", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Nama Siswa: $namaSiswa"),
              pw.Text("Kelas: ${namaKelas.value}"),
            ]
          ),
          pw.Divider(height: 20),
          pw.Table.fromTextArray(
            headers: ['Tanggal', 'Kategori', 'Materi', 'Nilai', 'Catatan'],
            data: catatanList.map((doc) {
              final data = doc.data();
              final timestamp = data['tanggal_penilaian'] as Timestamp;
              final tanggal = DateFormat('dd-MM-yyyy').format(timestamp.toDate());
              return [
                tanggal,
                data['kategori'] ?? '',
                data['materi'] ?? '',
                (data['nilai'] ?? 0).toString(),
                data['catatan_guru'] ?? '',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(5),
            border: pw.TableBorder.all(),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}

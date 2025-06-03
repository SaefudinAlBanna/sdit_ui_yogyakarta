import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TanggapanCatatanKhususSiswaWalikelasController extends GetxController {
  var dataArgumen = Get.arguments;

  String? _idTahunAjaranCache;

  TextEditingController tanggapanWaliKelasC = TextEditingController();

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  String idUser = FirebaseAuth.instance.currentUser!.uid;
  String idSekolah = "20404148";
  String emailAdmin = FirebaseAuth.instance.currentUser!.email!;

  String? idTahunAjaran;

  @override
  void onInit() async {
    super.onInit();
    String tahunajaranya = await getTahunAjaranTerakhir();
    idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    update();
  }

  void clearForm() {
    tanggapanWaliKelasC.clear();
    // selectedDropdownItem.value = null; // Reset dropdown
    // Tambahkan pembersihan untuk widget lain di sini jika ada
    // print("Form dibersihkan!");
  }

  @override
  void onClose() {
    // Penting untuk dispose controller ketika GetX controller ditutup
    tanggapanWaliKelasC.dispose();
    super.onClose();
  }

  // Helper untuk mendapatkan idTahunAjaran yang sudah diformat
  Future<String> getFormattedIdTahunAjaran() async {
    if (_idTahunAjaranCache != null) return _idTahunAjaranCache!;
    String tahunajaranya = await getTahunAjaranTerakhir();
    _idTahunAjaranCache = tahunajaranya.replaceAll("/", "-");
    return _idTahunAjaranCache!;
  }

  Future<String> getTahunAjaranTerakhir() async {
    CollectionReference<Map<String, dynamic>> colTahunAjaran = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran');
    QuerySnapshot<Map<String, dynamic>> snapshotTahunAjaran =
        await colTahunAjaran.get();
    List<Map<String, dynamic>> listTahunAjaran =
        snapshotTahunAjaran.docs.map((e) => e.data()).toList();
    String tahunAjaranTerakhir =
        listTahunAjaran.map((e) => e['namatahunajaran']).toList().last;
    return tahunAjaranTerakhir;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getDataSiswa() async* {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
       
          yield* firestore
              .collection('Sekolah')
              .doc(idSekolah)
              .collection('pegawai')
              .doc(idUser)
              .collection('tahunajaran')
              .doc(idTahunAjaran)
              .collection('kelas')
              .doc(dataArgumen)
              .collection('catatansiswa')
              .snapshots();
    
  }

  Future<void> updateTanggapanWaliKelas(
    String docIdCatatanSiswa, // ID unik dari dokumen catatansiswa
    String idKepalaSekolahDariData, // Diambil dari data catatansiswa
    String idGuruBK, 
    String idSiswaDariData, // Diambil dari data catatansiswa (misal, nisn)
    // String idKelasDariData, // Ini adalah dataArgumen, sudah ada di controller
  ) async {
    if (tanggapanWaliKelasC.text.trim().isEmpty) {
      Get.snackbar("Error", "Tanggapan tidak boleh kosong.");
      return;
    }

    final String idKelas = dataArgumen; // idKelas dari argumen
    final String formattedIdTahunAjaran = await getFormattedIdTahunAjaran();
    final String tanggapanBaru = tanggapanWaliKelasC.text;

    WriteBatch batch = firestore.batch();

    // 1. UPDATE PADA COLLECTION WALI KELAS (PENGGUNA SAAT INI)
    DocumentReference waliKelasRef = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(idUser) // idWaliKelas saat ini
        .collection('tahunajaran')
        .doc(formattedIdTahunAjaran)
        .collection('kelas')
        .doc(idKelas)
        .collection('catatansiswa')
        .doc(docIdCatatanSiswa);
    batch.update(waliKelasRef, {'tanggapanwalikelas': tanggapanBaru});

    // 2. UPDATE PADA COLLECTION KEPALA SEKOLAH
    // Asumsi struktur path mirip, hanya idPegawai-nya yang beda
    DocumentReference kepalaSekolahRef = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(idKepalaSekolahDariData) // ID Kepala Sekolah dari data catatan
        .collection('tahunajaran')
        .doc(formattedIdTahunAjaran)
        .collection('kelas')
        .doc(idKelas) // Asumsi Kepala Sekolah juga melihat per kelas
        .collection('catatansiswa')
        .doc(docIdCatatanSiswa);
    batch.update(kepalaSekolahRef, {'tanggapanwalikelas': tanggapanBaru});

    DocumentReference guruBKRef = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(idGuruBK) // ID Siswa dari data catatan (misal, nisn)
        .collection('tahunajaran') // Asumsi ada subcollection tahunajaran
        .doc(formattedIdTahunAjaran) // Menggunakan tahun ajaran yang sama
        .collection('kelas')
        .doc(idKelas) // Asumsi Kepala Sekolah juga melihat per
        .collection('catatansiswa')
        .doc(docIdCatatanSiswa);
    batch.update(guruBKRef, {'tanggapanwalikelas': tanggapanBaru});

    // 3. UPDATE PADA COLLECTION SISWA
    // Asumsi `idSiswaDariData` adalah document ID di collection `siswa`
    // dan catatan siswa disimpan di subcollection `catatansiswa` di bawah siswa,
    // mungkin juga di bawah `tahunajaran` siswa tersebut.
    DocumentReference siswaRef = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('siswa')
        .doc(idSiswaDariData) // ID Siswa dari data catatan (misal, nisn)
        .collection('tahunajaran') // Asumsi ada subcollection tahunajaran
        .doc(formattedIdTahunAjaran) // Menggunakan tahun ajaran yang sama
        .collection('catatansiswa')
        .doc(docIdCatatanSiswa);
    batch.update(siswaRef, {'tanggapanwalikelas': tanggapanBaru});

    try {
      await batch.commit();
      Get.back(); // Tutup dialog
      Get.snackbar("Sukses", "Tanggapan berhasil diperbarui di semua lokasi.");
      clearForm(); // Panggil clearForm setelah sukses dan dialog ditutup
    } catch (e) {
      print("Error updating tanggapan: $e");
      Get.snackbar("Error", "Gagal memperbarui tanggapan: ${e.toString()}");
    }
  }

  void test() {
    print("dataArgumen (idKelas): $dataArgumen");
    print("idUser (idWaliKelas): $idUser");
    // Jika ingin test getTahunAjaranTerakhir:
    // getTahunAjaranTerakhir().then((value) => print("Tahun Ajaran Terakhir: $value"));
  }
}


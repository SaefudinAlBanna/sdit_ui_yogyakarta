import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PembayaranSppController extends GetxController {
  var dataArgumen = Get.arguments;

  TextEditingController pembayaranC = TextEditingController();
  TextEditingController bulanC = TextEditingController(); // Untuk dropdown bulan SPP
  TextEditingController nominalAtauKeteranganC = TextEditingController(); // Untuk TextField lainnya

  // Add this Rx variable for dropdown selection
  Rxn<String> selectedItem = Rxn<String>();

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
    // update();
  }

   void clearForm() {
    pembayaranC.clear();
    selectedItem.value = null; // Reset dropdown
    bulanC.clear(); // Bersihkan controller bulan
    nominalAtauKeteranganC.clear(); // Bersihkan controller nominal/keterangan
    // Tambahkan pembersihan untuk widget lain di sini jika ada
    // print("Form dibersihkan!");
  }

  void clearDetailPembayaranForm() {
    bulanC.clear();
    nominalAtauKeteranganC.clear();
  }

  @override
  void onClose() {
    pembayaranC.dispose();
    bulanC.dispose(); // Dispose controller bulan
    nominalAtauKeteranganC.dispose(); // Dispose controller nominal/keterangan
    super.onClose();
  }


  List<String> getListBulan() {
    return [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
  }


  List<String> getDataPembayaranList() {
    List<String> pembayaranList = [
      'Pendaftaran',
      'Buku / Modul',
      'Daftar Ulang',
      'Kegiatan',
      'Iuran Pangkal',
      'UPK / ASPD',
      'Seragam',
      'Iuran Komite',
      'SPP',
      'Infaq',
      'Lain-Lain',

    ];
    return pembayaranList;
  }


  // Future<String> getTahunAjaranTerakhir() async {
  //   CollectionReference<Map<String, dynamic>> colTahunAjaran = firestore
  //       .collection('Sekolah')
  //       .doc(idSekolah)
  //       .collection('tahunajaran');
  //   QuerySnapshot<Map<String, dynamic>> snapshotTahunAjaran =
  //       await colTahunAjaran.get();
  //   List<Map<String, dynamic>> listTahunAjaran =
  //       snapshotTahunAjaran.docs.map((e) => e.data()).toList();
  //   String tahunAjaranTerakhir =
  //       listTahunAjaran.map((e) => e['namatahunajaran']).toList().last;
  //   return tahunAjaranTerakhir;
  // }

  Future<String> getTahunAjaranTerakhir() async {
    // Pastikan idSekolah sudah terinisialisasi
    if (idSekolah.isEmpty) { // Contoh validasi sederhana
      print("Error: idSekolah belum diatur");
      return Future.error("idSekolah belum diatur");
    }
    CollectionReference<Map<String, dynamic>> colTahunAjaran = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran');
    QuerySnapshot<Map<String, dynamic>> snapshotTahunAjaran =
    await colTahunAjaran.orderBy('namatahunajaran', descending: false).get(); // Order untuk ambil yg terakhir
    
    if (snapshotTahunAjaran.docs.isEmpty) {
      return Future.error("Tidak ada data tahun ajaran");
    }
    
    List<Map<String, dynamic>> listTahunAjaran =
    snapshotTahunAjaran.docs.map((e) => e.data()).toList();
    String tahunAjaranTerakhir =
    listTahunAjaran.map((e) => e['namatahunajaran'] as String).toList().last;
    return tahunAjaranTerakhir;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getDataSiswa() async {
    // Pastikan idTahunAjaran sudah terinisialisasi dari onInit
    if (idTahunAjaran == null || idTahunAjaran!.isEmpty) {
      String tahunajaranya = await getTahunAjaranTerakhir();
      idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    }
    
    return await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelastahunajaran')
        .doc(dataArgumen) // Pastikan dataArgumen adalah ID kelas yang valid
        .collection('daftarsiswa')
        .get();
  }


   Stream<QuerySnapshot<Map<String, dynamic>>> getDataPembayaran(String idsiswa) async* {
     // Pastikan idTahunAjaran sudah terinisialisasi dari onInit
    if (idTahunAjaran == null || idTahunAjaran!.isEmpty) {
      String tahunajaranya = await getTahunAjaranTerakhir();
      idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    }

    // Pastikan pembayaranC.text tidak kosong sebelum digunakan sebagai nama koleksi
    if (pembayaranC.text.isEmpty) {
      // Handle kasus dimana jenis pembayaran belum dipilih, mungkin yield stream kosong atau error
      yield* Stream.error("Jenis pembayaran belum dipilih");
      return;
    }

    yield* firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelastahunajaran')
        .doc(dataArgumen) // ID Kelas
        .collection('daftarsiswa')
        .doc(idsiswa) // NISN Siswa
        .collection(pembayaranC.text) // Nama Jenis Pembayaran (e.g., "SPP", "Buku / Modul")
        .snapshots();
  }

   // Fungsi untuk menyimpan pembayaran (Anda perlu mengimplementasikan logika penyimpanannya)
  Future<void> simpanPembayaran(String idSiswa, String namaSiswa) async {
    if (pembayaranC.text.isEmpty) {
      Get.snackbar("Error", "Jenis pembayaran belum dipilih.");
      return;
    }

    // Pastikan idTahunAjaran sudah terinisialisasi
    if (idTahunAjaran == null || idTahunAjaran!.isEmpty) {
      Get.snackbar("Error", "Tahun ajaran tidak ditemukan.");
      return;
    }
    
    Map<String, dynamic> dataPembayaran = {
      'tglbayar': Timestamp.now(),
      // 'tglbayar': DateTime.now().toIso8601String(),
      'petugas': emailAdmin, // atau nama petugas jika ada
      // 'idsiswa': idSiswa, // sudah bagian dari path
      // 'namasiswa': namaSiswa, // sudah bagian dari path
    };

    String idPembayaranUnik = DateTime.now().millisecondsSinceEpoch.toString(); // ID unik untuk dokumen pembayaran

    if (pembayaranC.text == "SPP") {
      if (bulanC.text.isEmpty) {
        Get.snackbar("Peringatan", "Bulan SPP belum dipilih.");
        return;
      }
      dataPembayaran['bulan'] = bulanC.text;
      dataPembayaran['status'] = "Lunas"; // atau status lain
      idPembayaranUnik = bulanC.text; // Untuk SPP, bisa gunakan bulan sebagai ID jika unik per tahun
    } else {
      if (nominalAtauKeteranganC.text.isEmpty) {
        Get.snackbar("Peringatan", "Nominal atau keterangan belum diisi.");
        return;
      }
      dataPembayaran['detail'] = nominalAtauKeteranganC.text;
      // Anda mungkin ingin menambahkan field 'nominal' jika itu angka
      if (double.tryParse(nominalAtauKeteranganC.text) != null) {
         dataPembayaran['nominal'] = double.parse(nominalAtauKeteranganC.text);
      }
    }

    try {
      Get.dialog(Center(child: CircularProgressIndicator()), barrierDismissible: false); // Show loading

      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelastahunajaran')
          .doc(dataArgumen) // ID Kelas
          .collection('daftarsiswa')
          .doc(idSiswa) // NISN Siswa
          .collection(pembayaranC.text) // Nama Jenis Pembayaran
          .doc(idPembayaranUnik) // ID untuk item pembayaran ini (misal: nama bulan untuk SPP, atau timestamp untuk lain2)
          .set(dataPembayaran);
      
      Get.back(); // Close loading dialog
      Get.back(); // Close input payment dialog
      // Get.back(); // Opsional: Close bottom sheet jika mau

      Get.snackbar("Sukses", "Pembayaran ${pembayaranC.text} berhasil disimpan.");
      clearDetailPembayaranForm(); // Bersihkan form detail setelah simpan

    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar("Error", "Gagal menyimpan pembayaran: ${e.toString()}");
      print("Error simpan pembayaran: $e");
    }
  }


}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class JurnalAjarHarianController extends GetxController {
  // RxString jenisKelamin = "".obs;
  RxBool isLoading = false.obs;
  RxBool isLoadingTambahSiswa = false.obs;
   RxString selectedKelasObs = "".obs;
    RxString selectedMapelObs = "".obs; // Bisa juga untuk mapel jika 

  TextEditingController istirahatsholatC = TextEditingController();
  TextEditingController materimapelC = TextEditingController();
  TextEditingController kelasSiswaC = TextEditingController();
  TextEditingController mapelC = TextEditingController();
  TextEditingController catatanjurnalC = TextEditingController();

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  String idUser = FirebaseAuth.instance.currentUser!.uid;
  String idSekolah = '20404148';
  String emailAdmin = FirebaseAuth.instance.currentUser!.email!;

  // Saat kelasSiswaC berubah, update juga selectedKelasObs
  void onKelasChanged(String? value) {
    if (value != null) {
      kelasSiswaC.text = value;
      selectedKelasObs.value = value; // Update observable
      mapelC.clear(); // Kosongkan mapel
      selectedMapelObs.value = ""; // Kosongkan observable mapel jika ada
      // print("Kelas dipilih: ${selectedKelasObs.value}");
    } else {
      kelasSiswaC.clear();
      selectedKelasObs.value = "";
    }
  }

  void onMapelChanged(String? value) {
    if (value != null) {
      mapelC.text = value;
      selectedMapelObs.value = value;
    } else {
      mapelC.clear();
      selectedMapelObs.value = "";
    }
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

  Future<QuerySnapshot<Map<String, dynamic>>> tampilkanJamPelajaran() async {
    try {
      return await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('jampelajaran')
          .get();
    } catch (e) {
      throw Exception(
        'Data Matapelajaran tidak bisa diakses, silahkan ulangi lagi',
      );
    }
  }

  Future<List<String>> getDataKelas() async {
    String tahunajaranya =
        await getTahunAjaranTerakhir(); // ambil dari tahun ajaran di collection pegawai
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    List<String> kelasList = [];
    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelasaktif')
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            kelasList.add(docSnapshot.id);
          }
        });
    return kelasList;
  }

  // Future<List<String>> getDataMapel() async {
  //   // ignore: unnecessary_null_comparison
  //   if (kelasSiswaC.text == null || kelasSiswaC.text.isEmpty) {
  //     // Tampilkan pesan jika data kosong
  //     Get.snackbar("Data Kosong", "Silahkan pilih kelas terlebih dahulu");
  //     return [];
  //   } else {
  //     String tahunajaranya = await getTahunAjaranTerakhir();
  //     String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
  //     List<String> mapelkelasList = [];
  //     await firestore
  //         .collection('Sekolah')
  //         .doc(idSekolah)
  //         .collection('pegawai')
  //         .doc(idUser)
  //         .collection('tahunajaran')
  //         .doc(idTahunAjaran)
  //         .collection('kelasnya')
  //         .doc(kelasSiswaC.text)
  //         .collection('matapelajaran')
  //         .get()
  //         .then((querySnapshot) {
  //           for (var docSnapshot in querySnapshot.docs) {
  //             mapelkelasList.add(docSnapshot.id);
  //           }
  //         });
  //     return mapelkelasList;
  //   }
  // }

  Future<List<String>> getDataMapel() async {
  // 1. Validasi apakah kelas sudah dipilih
  if (kelasSiswaC.text.trim().isEmpty) {
    // Jika kelas belum dipilih, kembalikan list kosong.
    // DropdownSearch akan menampilkan "Tidak ada data" atau state kosongnya.
    // Get.snackbar bisa mengganggu jika ini dipanggil berkali-kali oleh DropdownSearch.
    // print("getDataMapel: Kelas belum dipilih, mengembalikan list kosong.");
    return [];
  }

  if (selectedKelasObs.value.trim().isEmpty) {
      return [];
    }

  // Opsional: Set state loading untuk dropdown mapel jika Anda punya
  // isLoadingMapel.value = true;
  // print("getDataMapel: Mengambil mapel untuk kelas: ${kelasSiswaC.text}");

  try {
    // 2. Dapatkan tahun ajaran terakhir (fungsi ini sudah ada dan di-await)
    final String tahunAjaranRaw = await getTahunAjaranTerakhir();
    final String idTahunAjaranFormatted = tahunAjaranRaw.replaceAll("/", "-");

    // 3. Bangun path query ke Firestore
    // Pastikan semua ID (idSekolah, idUser, idTahunAjaranFormatted, kelasSiswaC.text) valid
    final QuerySnapshot<Map<String, dynamic>> querySnapshot = await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(idUser) // Mengambil mapel yang diajar oleh guru ini
        .collection('tahunajaran')
        .doc(idTahunAjaranFormatted)
        .collection('kelasnya')
        .doc(kelasSiswaC.text) // Kelas yang dipilih
        .collection('matapelajaran') // Koleksi matapelajaran yang diajar guru di kelas tsb
        .get();

    // 4. Proses hasil query
    final List<String> mapelList = [];
    if (querySnapshot.docs.isNotEmpty) {
      for (var docSnapshot in querySnapshot.docs) {
        // Asumsi ID dokumen adalah nama mata pelajaran
        mapelList.add(docSnapshot.id);
      }
      // print("getDataMapel: Mapel ditemukan: $mapelList");
    } else {
      // print("getDataMapel: Tidak ada mapel ditemukan untuk kelas ${kelasSiswaC.text} atau path tidak valid.");
      // Jika tidak ada dokumen, berarti tidak ada mapel yang terdaftar untuk guru/kelas tersebut.
      // Tidak perlu Get.snackbar di sini, biarkan DropdownSearch menampilkan "Tidak ada data".
    }
    return mapelList;

  } catch (e) {
    // 5. Tangani error jika terjadi
    // print("getDataMapel: Error saat mengambil data mapel - $e");
    Get.snackbar(
      "Error",
      "Gagal mengambil data mata pelajaran. Silakan coba lagi.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
    );
    return []; // Kembalikan list kosong jika terjadi error
  } finally {
    // Opsional: Set state loading false setelah selesai
    // isLoadingMapel.value = false;
  }
}

  Future<void> simpanDataJurnal(String jampelajaran) async {
    String tahunAjaran = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunAjaran.replaceAll("/", "-");

    DateTime now = DateTime.now();
    String docIdJurnal = DateFormat.yMd().format(now).replaceAll('/', '-');

    String idKelas = kelasSiswaC.text;
    String namamapel = mapelC.text;

    QuerySnapshot<Map<String, dynamic>> querySnapshotKelompok =
        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('pegawai')
            .where('uid', isEqualTo: idUser)
            .get();
    if (querySnapshotKelompok.docs.isNotEmpty) {
      Map<String, dynamic> dataGuru = querySnapshotKelompok.docs.first.data();
      String namaGuru = dataGuru['alias'];

      //ini untuk "tahap awal" ditampilkan pada wali/ortu
      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelasaktif')
          .doc(idKelas)
          .collection('tanggaljurnal')
          .doc(docIdJurnal)
          .set({
            'kelas': idKelas,
            'namamapel': namamapel,
            'tanggalinput': DateTime.now().toIso8601String(),
            'idpenginput': idUser,
            'emailpenginput': emailAdmin,
            'namapenginput': namaGuru,
            'uidtanggal': docIdJurnal,
          });

      //ini untuk ditampilkan pada wali/ortu
      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelasaktif')
          .doc(idKelas)
          .collection('tanggaljurnal')
          .doc(docIdJurnal)
          .collection('jurnalkelas')
          .doc(jampelajaran)
          .set({
            'namamapel': namamapel,
            'kelas': idKelas,
            'tanggalinput': DateTime.now().toIso8601String(),
            'idpenginput': idUser,
            'emailpenginput': emailAdmin,
            'namapenginput': namaGuru,
            'materipelajaran': materimapelC.text,
            'jampelajaran': jampelajaran,
            'uidtanggal': docIdJurnal,
            'catatanjurnal': catatanjurnalC.text,
          });

      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('jurnalharian')
          .doc(docIdJurnal)
          .set({
            'namamapel': namamapel,
            // 'kelas': idKelas,
            'tanggalinput': DateTime.now().toIso8601String(),
            'idpenginput': idUser,
            'emailpenginput': emailAdmin,
            'namapenginput': namaGuru,
            'uidtanggal': docIdJurnal,
            'catatanjurnal': catatanjurnalC.text,
            'materimapel': materimapelC.text,
            'jampelajaran': jampelajaran,
            'statusjurnal': 'Aktif',
            'statusjurnalwali': 'Aktif',
            'statusjurnalortu': 'Aktif',
            'statusjurnalkelas': 'Aktif',
            'statusjurnaladmin': 'Aktif',
          });

      //ini untuk ditampilkan dihome semua kelas berdasarkan jam
      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('jurnalharian')
          .doc(docIdJurnal)
          .collection('jampelajaran')
          .doc(jampelajaran)
          .set({
            'namamapel': namamapel,
            'kelas': idKelas,
            'tanggalinput': DateTime.now().toIso8601String(),
            'idpenginput': idUser,
            'emailpenginput': emailAdmin,
            'namapenginput': namaGuru,
            'materimapel': materimapelC.text,
            'jampelajaran': jampelajaran,
            'uidtanggal': docIdJurnal,
            'catatanjurnal': catatanjurnalC.text,
          });

      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('pegawai')
          .doc(idUser)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('tanggaljurnal')
          .doc(docIdJurnal)
          .set({
            // 'kelas': idKelas,
            'namamapel': namamapel,
            'tanggalinput': DateTime.now().toIso8601String(),
            'idpenginput': idUser,
            'emailpenginput': emailAdmin,
            'namapenginput': namaGuru,
            'uidtanggal': docIdJurnal,
          });

      //ini untuk catatn jurnal guru
      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('pegawai')
          .doc(idUser)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('tanggaljurnal')
          .doc(docIdJurnal)
          .collection('jurnalkelas')
          .doc(jampelajaran)
          .set({
            'kelas': idKelas,
            'namamapel': namamapel,
            'tanggalinput': DateTime.now().toIso8601String(),
            'idpenginput': idUser,
            'emailpenginput': emailAdmin,
            'namapenginput': namaGuru,
            'materipelajaran': materimapelC.text,
            'jampelajaran': jampelajaran,
            'uidtanggal': docIdJurnal,
            'catatanjurnal': catatanjurnalC.text,
          });

      Get.back();
      Get.snackbar("Berhasil", "Data jurnal berhasil disimpan");
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> tampilkanjurnal() async* {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    DateTime now = DateTime.now();
    String docIdJurnal = DateFormat.yMd().format(now).replaceAll('/', '-');

    yield* firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(idUser)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('tanggaljurnal')
        .doc(docIdJurnal)
        .collection('jurnalkelas')
        .where('uidtanggal', isEqualTo: docIdJurnal)
        .snapshots();
  }
}

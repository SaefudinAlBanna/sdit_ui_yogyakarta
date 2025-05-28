import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class JurnalAjarHarianController extends GetxController {
  // RxString jenisKelamin = "".obs;
  RxBool isLoading = false.obs;
  RxBool isLoadingTambahSiswa = false.obs;

  // TextEditingController ke1C = TextEditingController();
  // TextEditingController ke2C = TextEditingController();
  // TextEditingController ke3C = TextEditingController();
  // TextEditingController ke4C = TextEditingController();
  // TextEditingController ke5C = TextEditingController();
  // TextEditingController ke6C = TextEditingController();
  // TextEditingController ke7C = TextEditingController();
  // TextEditingController ke8C = TextEditingController();
  // TextEditingController ke9C = TextEditingController();
  // TextEditingController ke10C = TextEditingController();
  // TextEditingController ke11C = TextEditingController();
  // TextEditingController ke12C = TextEditingController();
  // TextEditingController ke13C = TextEditingController();
  // TextEditingController ke14C = TextEditingController();

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

  Future<List<String>> getDataMapel() async {
    if (kelasSiswaC.text == null || kelasSiswaC.text.isEmpty) {
      // Tampilkan pesan jika data kosong
      Get.snackbar("Data Kosong", "Silahkan pilih kelas terlebih dahulu");
      return [];
    } else {
      String tahunajaranya = await getTahunAjaranTerakhir();
      String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
      List<String> mapelkelasList = [];
      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('pegawai')
          .doc(idUser)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelasnya')
          .doc(kelasSiswaC.text)
          .collection('matapelajaran')
          .get()
          .then((querySnapshot) {
            for (var docSnapshot in querySnapshot.docs) {
              mapelkelasList.add(docSnapshot.id);
            }
          });
      return mapelkelasList;
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

      // await firestore
      //     .collection('Sekolah')
      //     .doc(idSekolah)
      //     .collection('pegawai')
      //     .doc(idUser)
      //     .collection('tahunajaran')
      //     .doc(idTahunAjaran)
      //     .collection('kelasnya')
      //     .doc(idKelas)
      //     .collection('tanggaljurnal')
      //     .doc(docIdJurnal)
      //     .set({
      //       'namamapel': namamapel,
      //       'tanggalinput':DateTime.now().toIso8601String(),
      //       'idpenginput': idUser,
      //       'emailpenginput' : emailAdmin,
      //       'namapenginput': namaGuru,
      //       'uidtanggal': docIdJurnal,
      //     });

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
        .snapshots();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class PemberianGuruMapelController extends GetxController {
  var argumenKelas = Get.arguments;

  TextEditingController idPegawaiC = TextEditingController();
  TextEditingController guruMapelC = TextEditingController();

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

  Future<List<String>> getDataGuruMapel() async {
    List<String> guruPengajar = [];

    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    QuerySnapshot<Map<String, dynamic>> snapKelas =
        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('tahunajaran')
            .doc(idTahunAjaran)
            .collection('kelastahunajaran')
            .get();

    // String namaGuruMapel =
    //     snapKelas.docs.isNotEmpty
    //         ? snapKelas.docs.first.data()['walikelas']
    //         : '';

    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        // .where('alias', isNotEqualTo: namaGuruMapel)
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs.where(
            (doc) => doc['role'] == 'Pengampu' || doc['role'] == "Guru Kelas",
          )) {
            guruPengajar.add(docSnapshot.data()['alias']);
          }
        });
    return guruPengajar;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> tampilkanMapel() async {
    try {
      return await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('matapelajaran')
          .get();
    } catch (e) {
      throw Exception(
        'Data Matapelajaran tidak bisa diakses, silahkan ulangi lagi',
      );
    }
  }

  // final _streamController = StreamController<QuerySnapshot<Map<String, dynamic>>>();
  // Stream<QuerySnapshot<Map<String, dynamic>>> get stream => _streamController.stream;

  Future<void> simpanMapel(String namaMapel) async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    String kelasNya = argumenKelas.substring(0, 1);
    String faseNya =
        (kelasNya == '1' || kelasNya == '2')
            ? "Fase A"
            : (kelasNya == '3' || kelasNya == '4')
            ? "Fase B"
            : "Fase C";

    QuerySnapshot<Map<String, dynamic>> querySnapshotKelompok =
        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('pegawai')
            .where('alias', isEqualTo: guruMapelC.text)
            .get();
    if (querySnapshotKelompok.docs.isNotEmpty) {
      Map<String, dynamic> dataGuru = querySnapshotKelompok.docs.first.data();
      String idGuru = dataGuru['uid'];

      CollectionReference<Map<String, dynamic>> colKelasAktif = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelasaktif');

      // DocumentReference<Map<String, dynamic>> docKelasAktif = colKelasAktif.doc(argumenKelas);

      QuerySnapshot<Map<String, dynamic>> snapKelasAktif =
          await colKelasAktif.where('namakelas', isEqualTo: argumenKelas).get();
      if (snapKelasAktif.docs.isEmpty) {
        Get.snackbar(
          "Error",
          "Kelas tidak ditemukan. silahkan input kelas dulu",
        );
        // throw Exception('Kelas tidak ditemukan');
      }

      CollectionReference<Map<String, dynamic>> colMapelKelas = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelasmapel')
          .doc(argumenKelas)
          .collection('matapelajaran');

      DocumentReference<Map<String, dynamic>> docMapel = colMapelKelas.doc(
        namaMapel,
      );

      QuerySnapshot<Map<String, dynamic>> snapMapel =
          await colMapelKelas
              .where('namamatapelajaran', isEqualTo: namaMapel)
              .get();
      if (snapMapel.docs.isNotEmpty) {
        // Jika ada dokumen dengan namaMapel yang sama, tampilkan pesan error
        Get.snackbar("Error", "Mata pelajaran dengan nama ini sudah ada.");
        return;
      } else {
        // Jika tidak ada dokumen dengan namaMapel yang sama, simpan data

        DocumentReference<Map<String, dynamic>> docTahunAjaranGuru = firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('pegawai')
            .doc(idGuru)
            .collection('tahunajaran')
            .doc(idTahunAjaran);

        DocumentSnapshot<Map<String, dynamic>> snapTahunAjaranGuru =
            await docTahunAjaranGuru.get();
        if (snapTahunAjaranGuru.exists) {
          // Map<String , dynamic> dataTahunAjaranGuru = snapTahunAjaranGuru.data();
          // dataTahunAjaranGuru['mapel'] = FieldValue.arrayUnion([nama Mapel]);
          await docTahunAjaranGuru.update({
            'tahunajaran': tahunajaranya,
            'emailpenginputMapel': emailAdmin,
            'idpenginputMapel': idUser,
          });
        } else {
          // Map<String , dynamic> dataTahunAjaranGuru = {
          //   'mapel' : [namaMapel]
          await docTahunAjaranGuru.set({
            'tahunajaran': tahunajaranya,
            'emailpenginputMapel': emailAdmin,
            'idpenginputMapel': idUser,
          });
        }
        // Simpan data disini
        // await firestore
        //     .collection('Sekolah')
        //     .doc(idSekolah)
        //     .collection('pegawai')
        //     .doc(idGuru)
        //     .collection('tahunajaran')
        //     .doc(idTahunAjaran)
        //     .update({
        //       'tahunajaran': tahunajaranya,
        //       'emailpenginputMapel': emailAdmin,
        //       'idpenginputMapel': idUser,
        //     });



        DocumentReference<Map<String, dynamic>> docGuruKelas = firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('pegawai')
            .doc(idGuru)
            .collection('tahunajaran')
            .doc(idTahunAjaran)
            .collection('kelasnya')
            .doc(argumenKelas);

            DocumentSnapshot<Map<String, dynamic>> snapGuruKelas = await docGuruKelas.get();
        if (snapGuruKelas.exists) {
          // Map<String , dynamic> dataTahunAjaranGuru = snapTahunAjaranGuru.data();
          // dataTahunAjaranGuru['mapel'] = FieldValue.arrayUnion([nama Mapel]);
          await docGuruKelas.update({
            'tahunajaran': tahunajaranya,
          'emailpenginputMapel': emailAdmin,
          'idpenginputMapel': idUser,
          'fase': faseNya,
          });
        } else {
          // Map<String , dynamic> dataTahunAjaranGuru = {
          //   'mapel' : [namaMapel]
          await docGuruKelas.set({
            'tahunajaran': tahunajaranya,
          'emailpenginputMapel': emailAdmin,
          'idpenginputMapel': idUser,
          'fase': faseNya,
          });
        }

        // colGuru.doc(argumenKelas).update({
        //   'tahunajaran': tahunajaranya,
        //   'emailpenginputMapel': emailAdmin,
        //   'idpenginputMapel': idUser,
        //   'fase': faseNya,
        // });

        DocumentReference<Map<String, dynamic>> docGuruKelasMapel = docGuruKelas.collection('matapelajaran').doc(namaMapel);

        DocumentSnapshot<Map<String, dynamic>> snapGuruKelasMapel = await docGuruKelasMapel.get();

        if (snapGuruKelasMapel.exists) {
          // Map<String , dynamic> dataTahunAjaranGuru = snapTahunAjaranGuru.data();
          // dataTahunAjaranGuru['mapel'] = FieldValue.arrayUnion([nama Mapel]);
          await docGuruKelas.update({
              'tahunajaran': tahunajaranya,
              'emailpenginputMapel': emailAdmin,
              'idpenginputMapel': idUser,
              'namaMapel': namaMapel,
              'idKelas': argumenKelas,
              'idSekolah': idSekolah,
              'idGuru': idGuru,
              'idTahunAjaran': idTahunAjaran,
              'fase': faseNya,
          });
        } else {
          // Map<String , dynamic> dataTahunAjaranGuru = {
          //   'mapel' : [namaMapel]
          await docGuruKelas.set({
              'tahunajaran': tahunajaranya,
              'emailpenginputMapel': emailAdmin,
              'idpenginputMapel': idUser,
              // 'namaMapel': namaMapel,
              'idKelas': argumenKelas,
              'idSekolah': idSekolah,
              'idGuru': idGuru,
              'idTahunAjaran': idTahunAjaran,
              'fase': faseNya,
          });
        }

        docGuruKelasMapel.set({
          'tahunajaran': tahunajaranya,
              'emailpenginputMapel': emailAdmin,
              'idpenginputMapel': idUser,
              'namaMapel': namaMapel,
              'idKelas': argumenKelas,
              'idSekolah': idSekolah,
              'idGuru': idGuru,
              'idTahunAjaran': idTahunAjaran,
              'fase': faseNya,
        });

        // colGuruk
        //     .doc(argumenKelas)
        //     .collection('matapelajaran')
        //     .doc(namaMapel)
        //     .update({
        //       'tahunajaran': tahunajaranya,
        //       'emailpenginputMapel': emailAdmin,
        //       'idpenginputMapel': idUser,
        //       'namaMapel': namaMapel,
        //       'idKelas': argumenKelas,
        //       'idSekolah': idSekolah,
        //       'idGuru': idGuru,
        //       'idTahunAjaran': idTahunAjaran,
        //       'fase': faseNya,
        //     });

        docMapel.set({
          'fase': faseNya,
          'namamatapelajaran': namaMapel,
          'guru': guruMapelC.text,
          'idGuru': idGuru,
          'idSekolah': idSekolah,
          'idTahunAjaran': idTahunAjaran,
          'idKelas': argumenKelas,
          'idMapel': namaMapel,
          // 'idSiswa': '',
          // 'idGuruMapel': '',
          'status': 'aktif',
          'idPenginputMapel': idUser,
          'tanggalinputMapel': DateTime.now().toIso8601String(),
          // 'updateinput': DateTime.now().toIso8601String(),
        });

        firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('tahunajaran')
            .doc(idTahunAjaran)
            .collection('kelasmapel')
            .doc(argumenKelas)
            .set({
              'tahunajaran': tahunajaranya,
              'emailpenginputMapel': emailAdmin,
              'idpenginputMapel': idUser,
              'fase': faseNya,
              'tanggalinputMapel': DateTime.now().toIso8601String(),
              'namakelas': argumenKelas,
            });

        colMapelKelas.doc(namaMapel).set({
          'fase': faseNya,
          'namamatapelajaran': namaMapel,
          'guru': guruMapelC.text,
          'idGuru': idGuru,
          'idSekolah': idSekolah,
          'idTahunAjaran': idTahunAjaran,
          'idKelas': argumenKelas,
          'idMapel': namaMapel,
          'status': 'aktif',
          'idPenginputMapel': idUser,
          'tanggalinputMapel': DateTime.now().toIso8601String(),
          // 'updateinput': DateTime.now().toIso8601String(),
        });

        Get.snackbar("Berhasil", "Mata pelajaran berhasil disimpan.");
        // tampilkan();
      }
    }
  }

  Future<void> refreshTampilan() async {
    tampilkan();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> tampilkan() async* {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    yield* firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelasmapel')
        .doc(argumenKelas)
        .collection('matapelajaran')
        .snapshots();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';

class TambahKelompokMengajiController extends GetxController {
  TextEditingController kelasSiswaC = TextEditingController();
  TextEditingController tempatC = TextEditingController();
  TextEditingController semesterC = TextEditingController();
  TextEditingController pengampuC = TextEditingController();
  TextEditingController faseC = TextEditingController();

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  String idUser = FirebaseAuth.instance.currentUser!.uid;
  String idSekolah = '20404148';
  String emailAdmin = FirebaseAuth.instance.currentUser!.email!;


  Future<List<String>> getDataPengampu() async {
    List<String> pengampuList = [];
    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .get()
        .then((querySnapshot) {
      for (var docSnapshot
          in querySnapshot.docs.where((doc) => doc['role'] == 'Pengampu')) {
        pengampuList.add(docSnapshot.data()['alias']);
      }
    });
    return pengampuList;
  }

  List<String> getDataTempat() {
    List<String> temaptList = [
      'masjid',
      'aula',
      'kelas',
      'lab',
      'dll',
    ];
    return temaptList;
  }

  List<String> getDataSemester() {
    List<String> temaptList = [
      'semester1',
      'semester2',
    ];
    return temaptList;
  }

  List<String> getDataFase() {
    List<String> faseList = [
      'Fase A',
      'Fase B',
      'Fase C',
    ];
    return faseList;
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

  Future<QuerySnapshot<Map<String, dynamic>>> ambilDataHalaqoh() async {
    // DateTime now = DateTime.now();
    // String docIdNilai = DateFormat.yMd().format(now).replaceAll('/', '-');

    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    
    return await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelompokmengaji')
        .doc(faseC.text)
        .collection('pengampu')
        .doc(pengampuC.text)
        .collection('tempat')
        // .where('tanggalinputx', isEqualTo: docIdNilai)
        .orderBy('tanggalinput', descending: true)
        .get();
  }

  Future<void> dataxx() async {
    try {
      QuerySnapshot<Map<String, dynamic>> datanxx = await ambilDataHalaqoh();
      List<Map<String, dynamic>> datanya =
          datanxx.docs.map((doc) => doc.data()).toList();

      // ignore: prefer_is_empty
      if (datanya.isNotEmpty || datanya != [] || datanya.length != 0) {
        // Get.offAllNamed(Routes.TAMBAH_SISWA_KELOMPOK, arguments: datanya);
        // Get.back();
        // Get.offAllNamed(Routes.TAMBAH_SISWA_KELOMPOK, arguments: datanya);
        Get.back();
        Get.offAllNamed(Routes.KELOMPOK_HALAQOH, arguments: datanya);
        // print('ini data argumenXX = $datanya');
      } else if (datanya.isEmpty) {
        // print('ini yang kedua = $datanya');
        Get.snackbar('Error', 'data kosong, silahkan coba lagi');
      } else if (datanya.isEmpty || datanya == []) {
        Get.snackbar('Error', 'data kosong, silahkan coba lagi');
        // print('pengambilan data kalo null = $datanya');
      } else {
        // print('Error, bukan keduanya');
        Get.snackbar('Error', 'data kosong, silahkan coba lagi');
      }
    } catch (e) {
      Get.snackbar('Error', '$e');
      // print('kode error print nya : $e');
    }
  }

  Future<void> isiTahunAjaranKelompokPadaPegawai() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    // String semesterNya =
    //     (semesterC.text == 'semester1') ? "Semester I" : "Semester II";
    QuerySnapshot<Map<String, dynamic>> querySnapshotGuru = await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .where('alias', isEqualTo: pengampuC.text)
        .get();
    if (querySnapshotGuru.docs.isNotEmpty) {
      Map<String, dynamic> dataGuru = querySnapshotGuru.docs.first.data();
      String idPengampu = dataGuru['uid'];

      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('pegawai')
          .doc(idPengampu)
          .collection('tahunajarankelompok')
          .doc(idTahunAjaran)
          .set({'namatahunajaran': tahunajaranya});

      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('pegawai')
          .doc(idPengampu)
          .collection('tahunajarankelompok')
          .doc(idTahunAjaran)
          .set({
        // 'namasemester': semesterNya,
        'tahunajaran': tahunajaranya,
        'emailpenginput': emailAdmin,
        'idpenginput': idUser,
        'tanggalinput': DateTime.now().toIso8601String(),
      });

      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('pegawai')
          .doc(idPengampu)
          .collection('tahunajarankelompok')
          .doc(idTahunAjaran)
          // .collection('semester')
          // .doc(semesterNya)
          .collection('kelompokmengaji')
          .doc(faseC.text)
          .set({
        'fase': faseC.text,
        'tempatmengaji': tempatC.text,
        'namapengampu': pengampuC.text,
        'idpengampu': idPengampu,
        // 'namasemester': semesterNya,
        'tahunajaran': tahunajaranya,
        'emailpenginput': emailAdmin,
        'idpenginput': idUser,
        'tanggalinput': DateTime.now().toIso8601String(),
      });

      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('pegawai')
          .doc(idPengampu)
          .collection('tahunajarankelompok')
          .doc(idTahunAjaran)
          // .collection('semester')
          // .doc(semesterNya)
          .collection('kelompokmengaji')
          .doc(faseC.text)
          .collection('tempat')
          .doc(tempatC.text)
          .set({
        'fase': faseC.text,
        'tempatmengaji': tempatC.text,
        'namapengampu': pengampuC.text,
        'idpengampu': idPengampu,
        // 'namasemester': semesterNya,
        'tahunajaran': tahunajaranya,
        'emailpenginput': emailAdmin,
        'idpenginput': idUser,
        'tanggalinput': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> isiFieldPengampuKelompok() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    // String idKelompokmengaji = "${pengampuC.text} ${tempatC.text}";

    // String semesterNya =
    //     (semesterC.text == 'semester1') ? "Semester I" : "Semester II";

    QuerySnapshot<Map<String, dynamic>> querySnapshot = await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .where('alias', isEqualTo: pengampuC.text)
        .get();
    String idPengampu = querySnapshot.docs.first.data()['uid'];

    isiTahunAjaranKelompokPadaPegawai();

    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        // .collection('semester')
        // .doc(semesterNya)
        .collection('kelompokmengaji')
        .doc(faseC.text)
        .collection('pengampu')
        .doc(pengampuC.text)
        .collection('tempat')
        .doc(tempatC.text)
        .set({
      'fase': faseC.text,
      'tempatmengaji': tempatC.text,
      'tahunajaran': tahunajaranya,
      'kelompokmengaji': pengampuC.text,
      // 'namasemester': semesterNya,
      'namapengampu': pengampuC.text,
      'idpengampu': idPengampu,
      'emailpenginput': emailAdmin,
      'idpenginput': idUser,
      'tanggalinput': DateTime.now().toIso8601String(),
    });

    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        // .collection('semester')
        // .doc(semesterNya)
        .collection('kelompokmengaji')
        .doc(faseC.text)
        .collection('pengampu')
        .doc(pengampuC.text)
        .set({
      'fase': faseC.text,
      // 'namasemester': semesterNya,
      'kelompokmengaji': pengampuC.text,
      'idpengampu': idPengampu,
      'namapengampu': pengampuC.text,
      'tempatmengaji': tempatC.text,
      'tahunajaran': tahunajaranya,
      'emailpenginput': emailAdmin,
      'idpenginput': idUser,
      'tanggalinput': DateTime.now().toIso8601String(),
    });
  }

  // Future<void> buatIsiSemester1() async {
  //   String tahunajaranya = await getTahunAjaranTerakhir();
  //   String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

  //   // String semesterNya =
  //   //     (semesterC.text == 'semester1') ? "Semester I" : "Semester II";

  //   await firestore
  //       .collection('Sekolah')
  //       .doc(idSekolah)
  //       .collection('tahunajaran')
  //       .doc(idTahunAjaran)
  //       // .collection('semester')
  //       // .doc(semesterNya)
  //       .collection('kelompokmengaji')
  //       .doc(faseC.text)
  //       .collection('pengampu')
  //       .doc(pengampuC.text)
  //       .set({
  //     'namasemester': 'Semester I',
  //     'tahunajaran': tahunajaranya,
  //     'emailpenginput': emailAdmin,
  //     'idpenginput': idUser,
  //     'tanggalinput': DateTime.now().toIso8601String(),
  //   });
  // }
  
  Future<void> testBuat() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    // String semesterNya =
    //     (semesterC.text == 'semester1') ? "Semester I" : "Semester II";

    QuerySnapshot<Map<String, dynamic>> colTempat = await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        // .collection('semester')
        // .doc('Semester I')
        .collection('kelompokmengaji')
        .doc(faseC.text)
        .collection('pengampu')
        .doc(pengampuC.text)
        .collection('tempat')
        .get();

      if(colTempat.docs.length != 0) {
      // print('tempatC : ${colTempat.docs.length} ');
      Get.snackbar('Error',
          'Tidak bisa membuat kelompok, pengampu sudah punya kelompok');
    } else {
      // print('tempatC : ${colTempat.docs.length} ');

      try {
        QuerySnapshot<Map<String, dynamic>> querySnapshot = await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('pegawai')
            .where('alias', isEqualTo: pengampuC.text)
            .get();

        String idPengampu = querySnapshot.docs.first.data()['uid'];
        isiFieldPengampuKelompok();
        // buatIsiSemester1();

        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('tahunajaran')
            .doc(idTahunAjaran)
            // .collection('semester')
            // .doc('Semester I')
            .collection('kelompokmengaji')
            .doc(faseC.text)
            .set({
          'fase': faseC.text,
          'tahunajaran': tahunajaranya,
          // 'semester': 'Semester I',
          'emailpenginput': emailAdmin,
          'idpenginput': idUser,
          'tanggalinput': DateTime.now().toIso8601String(),
        });

        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('tahunajaran')
            .doc(idTahunAjaran)
            // .collection('semester')
            // .doc('Semester I')
            .collection('kelompokmengaji')
            .doc(faseC.text)
            .collection('pengampu')
            .doc(pengampuC.text)
            .collection('tempat')
            .doc(tempatC.text)
            .set({
          'fase': faseC.text,
          'tempatmengaji': tempatC.text,
          'tahunajaran': tahunajaranya,
          'kelompokmengaji': pengampuC.text,
          // 'namasemester': 'Semester I',
          'namapengampu': pengampuC.text,
          'idpengampu': idPengampu,
          'emailpenginput': emailAdmin,
          'idpenginput': idUser,
          'tanggalinput': DateTime.now().toIso8601String(),
          // 'tanggalinputx': docIdNilai,
        });

        Get.snackbar('Sukses', 'Kelompok mengaji berhasil dibuat');
        Get.defaultDialog(
            title: 'Grup Halaqoh berhasil',
            middleText: 'Silahkan klik buka kelompok',
            actions: <Widget>[
              ElevatedButton(
                  onPressed: () {
                    dataxx();
                  },
                  child: Text('buka kelompok'))
            ]);
      } catch (e) {
        Get.snackbar('ErrorXX', e.toString());
      }
    }
  }
}

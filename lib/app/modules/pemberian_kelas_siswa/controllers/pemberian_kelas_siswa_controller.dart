import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class PemberianKelasSiswaController extends GetxController {

  RxBool isLoading = false.obs;
  RxBool isLoadingTambahKelas = false.obs;
  var argumentKelas = Get.arguments;

  TextEditingController waliKelasSiswaC = TextEditingController();
  TextEditingController idPegawaiC = TextEditingController();
  TextEditingController namaSiswaC = TextEditingController();
  TextEditingController nisnSiswaC = TextEditingController();
  TextEditingController namaTahunAjaranTerakhirC = TextEditingController();
  
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  String idUser = FirebaseAuth.instance.currentUser!.uid;
  String idSekolah = '20404148';
  String emailAdmin = FirebaseAuth.instance.currentUser!.email!;

  late Stream<QuerySnapshot<Map<String, dynamic>>> tampilkanSiswa;

  @override
  void onInit() {
    super.onInit();

    tampilkanSiswa = FirebaseFirestore.instance
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('siswa')
        .where('status', isNotEqualTo: 'aktif')
        .snapshots();
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

  Future<List<String>> getDataWaliKelasBaru() async {
    List<String> waliKelasBaruList = [];

    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    QuerySnapshot<Map<String, dynamic>> snapKelas = await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelastahunajaran')
        .get();

    String namaWalikelas = snapKelas.docs.isNotEmpty
        ? snapKelas.docs.first.data()['walikelas']
        : '';

    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .where('alias', isNotEqualTo: namaWalikelas)
        .get()
        .then((querySnapshot) {
      for (var docSnapshot
          in querySnapshot.docs.where((doc) => doc['role'] == 'Guru Kelas')) {
        waliKelasBaruList.add(docSnapshot.data()['alias']);
        // waliKelasBaruList.add(docSnapshot.data()['nip']);
      }
    });
    return waliKelasBaruList;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getDataWali() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    CollectionReference<Map<String, dynamic>> colKelas = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelastahunajaran');

    try {
      // DocumentSnapshot<Map<String, dynamic>> docIdKelas =
      //     await colKelas.doc(argumentKelas).get();
      // Add your logic here if needed
      // if (docIdKelas.exists) {
      //   print('namakelas = ${docIdKelas['namakelas']}');
      //   print('walikelas = ${docIdKelas['walikelas']}');
      // } else {
      //   print('kelas tidak ada');
      // }
      return await colKelas.get();
      // Example return statement
    } catch (e) {
      // print('Error occurred: $e');
      throw Exception('Failed to fetch data: $e');
    }
  }

  Future<void> tambahDaftarKelasGuruAjar() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    String kelasNya = argumentKelas.substring(0, 1);
    String faseNya = (kelasNya == '1' || kelasNya == '2')
        ? "Fase A"
        : (kelasNya == '3' || kelasNya == '4')
            ? "Fase B"
            : "Fase C";

    //ambil data guru terpilih
    QuerySnapshot<Map<String, dynamic>> querySnapshotGuru = await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .where('alias', isEqualTo: waliKelasSiswaC.text)
        .get();
    if (querySnapshotGuru.docs.isNotEmpty) {
      Map<String, dynamic> dataGuru = querySnapshotGuru.docs.first.data();
      String uidGuru = dataGuru['uid'];

      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('pegawai')
          .doc(uidGuru)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .set({
        'namatahunajaran': tahunajaranya,
        'idpenginput': idUser,
        'tanggalinput': DateTime.now().toIso8601String(),
      });

      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('pegawai')
          .doc(uidGuru)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelasnya')
          .doc(argumentKelas)
          .set({
        'namakelas': argumentKelas,
        'fase': faseNya,
        'tahunajaran': tahunajaranya,
        'emailpenginput': emailAdmin,
        'idpenginput': idUser,
        'tanggalinput': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> kelasUntukSiswaNext(String nisnSiswa) async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    String kelasNya = argumentKelas.substring(0, 1);
    String faseNya = (kelasNya == '1' || kelasNya == '2')
        ? "Fase A"
        : (kelasNya == '3' || kelasNya == '4')
            ? "Fase B"
            : "Fase C";

    // QuerySnapshot<Map<String, dynamic>> querySnapshotSiswa = await firestore
    //     .collection('Sekolah')
    //     .doc(idSekolah)
    //     .collection('siswa')
    //     .where('nisn', isEqualTo: nisnSiswa)
    //     .get();
    // if (querySnapshotSiswa.docs.isNotEmpty) {
    //   Map<String, dynamic> dataSiswa = querySnapshotSiswa.docs.first.data();
    //   String uidSiswa = dataSiswa['uid'];

    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('siswa')
        .doc(nisnSiswa)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .set({
      'fase': faseNya,
      'nisn': nisnSiswa,
      'namatahunajaran': tahunajaranya,
      'idpenginput': idUser,
      'tanggalinput': DateTime.now().toIso8601String(),
    });

    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('siswa')
        .doc(nisnSiswa)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelasnya')
        .doc(argumentKelas)
        .set({
      'nisn': nisnSiswa,
      'namakelas': argumentKelas,
      'fase': faseNya,
      'tahunajaran': tahunajaranya,
      'emailpenginput': emailAdmin,
      'idpenginput': idUser,
      'tanggalinput': DateTime.now().toIso8601String(),
    });
    // }
  }

  Future<void> ubahStatusSiswaNext(String nisnSiSwa) async {
    // QuerySnapshot<Map<String, dynamic>> querySnapshotSiswa = await firestore
    //     .collection('Sekolah')
    //     .doc(idSekolah)
    //     .collection('siswa')
    //     .where('nisn', isEqualTo: nisnSiSwa)
    //     .get();
    // if (querySnapshotSiswa.docs.isNotEmpty) {
    //   Map<String, dynamic> dataSiswa = querySnapshotSiswa.docs.first.data();
    //   String uidSiswa = dataSiswa['uid'];

    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('siswa')
        .doc(nisnSiSwa)
        .update({
      'status': 'aktif',
    });
    // }
  }

  Future<void> buatIsiKelasTahunAjaran() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    String kelasNya = argumentKelas.substring(0, 1);
    String faseNya = (kelasNya == '1' || kelasNya == '2')
        ? "Fase A"
        : (kelasNya == '3' || kelasNya == '4')
            ? "Fase B"
            : "Fase C";

    QuerySnapshot<Map<String, dynamic>> querySnapshot = await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .where('alias', isEqualTo: waliKelasSiswaC.text)
        .get();

    // Check if the query returned any documents
    if (querySnapshot.docs.isEmpty) {
      Get.snackbar('Error',
          'Wali kelas tidak ditemukan. Pastikan alias wali kelas benar.');
      return; // Exit the function if no documents are found
    }

    String uidWaliKelasnya = querySnapshot.docs.first.data()['uid'];

    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelastahunajaran')
        .doc(argumentKelas)
        .set({
      'namakelas': argumentKelas,
      'fase': faseNya,
      'walikelas': waliKelasSiswaC.text,
      'idwalikelas': uidWaliKelasnya,
      'tahunajaran': tahunajaranya,
      'emailpenginput': emailAdmin,
      'idpenginput': idUser,
      'tanggalinput': DateTime.now().toIso8601String(),
    });
  }

  Future<void> buatIsiSemester1() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    String kelasNya = argumentKelas.substring(0, 1);
    String faseNya = (kelasNya == '1' || kelasNya == '2')
        ? "Fase A"
        : (kelasNya == '3' || kelasNya == '4')
            ? "Fase B"
            : "Fase C";

    QuerySnapshot<Map<String, dynamic>> querySnapshot = await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .where('alias', isEqualTo: waliKelasSiswaC.text)
        .get();

    // Check if the query returned any documents
    if (querySnapshot.docs.isEmpty) {
      Get.snackbar('Error',
          'Wali kelas tidak ditemukan. Pastikan alias wali kelas benar.');
      return; // Exit the function if no documents are found
    }

    String uidWaliKelasnya = querySnapshot.docs.first.data()['uid'];

    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelastahunajaran')
        .doc(argumentKelas)
        .collection('semester')
        .doc('Semester I')
        .set({
      'namasemester': 'Semester I',
      'namakelas': argumentKelas,
      'fase': faseNya,
      'walikelas': waliKelasSiswaC.text,
      'idwalikelas': uidWaliKelasnya,
      'tahunajaran': tahunajaranya,
      'emailpenginput': emailAdmin,
      'idpenginput': idUser,
      'tanggalinput': DateTime.now().toIso8601String(),
    });
  }

  Future<void> simpankelasSiswa(String namaSiswa, String nisnSiswa) async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    String kelasNya = argumentKelas.substring(0, 1);
    String faseNya = (kelasNya == '1' || kelasNya == '2')
        ? "Fase A"
        : (kelasNya == '3' || kelasNya == '4')
            ? "Fase B"
            : "Fase C";

    CollectionReference<Map<String, dynamic>> colKelas = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelastahunajaran');

    DocumentSnapshot<Map<String, dynamic>> docIdKelas =
        await colKelas.doc(argumentKelas).get();

    if (docIdKelas.exists) {
      // buatIsiKelasTahunAjaran();
      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelastahunajaran')
          .doc(argumentKelas)
          .set({
        'namakelas': argumentKelas,
        'fase': faseNya,
        'walikelas': docIdKelas['walikelas'],
        'idwalikelas': docIdKelas['idwalikelas'],
        'tahunajaran': tahunajaranya,
        'emailpenginput': emailAdmin,
        'idpenginput': idUser,
        'tanggalinput': DateTime.now().toIso8601String(),
      });

      // buatIsiSemester1();
      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelastahunajaran')
          .doc(argumentKelas)
          .collection('semester')
          .doc('Semester I')
          .set({
        'namasemester': 'Semester I',
        'namakelas': argumentKelas,
        'fase': faseNya,
        'walikelas': docIdKelas['walikelas'],
        'idwalikelas': docIdKelas['idwalikelas'],
        'tahunajaran': tahunajaranya,
        'emailpenginput': emailAdmin,
        'idpenginput': idUser,
        'tanggalinput': DateTime.now().toIso8601String(),
      });

      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelastahunajaran')
          .doc(argumentKelas)
          .collection('semester')
          .doc('Semester I')
          .collection('daftarsiswa')
          .doc(nisnSiswa)
          .set({
        'namasiswa': namaSiswa,
        'nisn': nisnSiswa,
        'fase': faseNya,
        'namakelas': docIdKelas['namakelas'],
        'namasemester': 'Semester I',
        'walikelas': docIdKelas['walikelas'],
        'idwalikelas': docIdKelas['idwalikelas'],
        'emailpenginput': emailAdmin,
        'idpenginput': idUser,
        'tanggalinput': DateTime.now().toIso8601String(),
        'status': 'aktif',
        'idsiswa': nisnSiswa,
        'statuskelompok': 'baru',
      });

      tambahDaftarKelasGuruAjar();

      kelasUntukSiswaNext(nisnSiswa);
      // ubahStatusSiswa(nisnSiswa);
      ubahStatusSiswaNext(nisnSiswa);
    } else if (!docIdKelas.exists) {
      try {
        QuerySnapshot<Map<String, dynamic>> querySnapshot = await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('pegawai')
            .where('alias', isEqualTo: waliKelasSiswaC.text)
            .get();

        String uidWaliKelasnya = querySnapshot.docs.first.data()['uid'];

        //=====================================================================

        List<String> waliKelasBaruList = [];
        QuerySnapshot<Map<String, dynamic>> snapKelas = await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('tahunajaran')
            .doc(idTahunAjaran)
            .collection('kelastahunajaran')
            .get();

        //menampilkan data wali kelas baru yang tidak ada pada semua document
        for (var doc in snapKelas.docs) {
          if (doc.data()['walikelas'] != null) {
            waliKelasBaruList.add(doc.data()['walikelas']);
          }
        }
        waliKelasBaruList = waliKelasBaruList.toSet().toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

        //  if(waliKelasBaruList.exists) {
        //   Get.snackbar('Error', 'Wali kelas sudah ada');
        //  }

        //=========================================================================

        if (uidWaliKelasnya.isEmpty) {
          Get.snackbar('Peringatan', 'Wali kelas tidak oleh kosong');
        } else if (waliKelasBaruList.contains(waliKelasSiswaC.text)) { // apabila wali kelas sudah ada di kelas lain
        Get.snackbar('Error', 'Wali kelas sudah ada, silahkan pilih yang lain');
        } else {
          // print('Jalankan perintah');
          buatIsiKelasTahunAjaran();
          buatIsiSemester1();
          tambahDaftarKelasGuruAjar();

          await firestore
              .collection('Sekolah')
              .doc(idSekolah)
              .collection('tahunajaran')
              .doc(idTahunAjaran)
              .collection('kelastahunajaran')
              .doc(argumentKelas)
              .collection('semester')
              .doc('Semester I')
              .collection('daftarsiswa')
              .doc(nisnSiswa)
              .set({
            'namasiswa': namaSiswa,
            'nisn': nisnSiswa,
            'fase': faseNya,
            'namakelas': argumentKelas,
            'namasemester': 'Semester I',
            'walikelas': waliKelasSiswaC.text,
            'idwalikelas': uidWaliKelasnya,
            'emailpenginput': emailAdmin,
            'idpenginput': idUser,
            'tanggalinput': DateTime.now().toIso8601String(),
            'status': 'aktif',
            'idsiswa': nisnSiswa,
            'statuskelompok': 'baru',
          });

         
          kelasUntukSiswaNext(nisnSiswa);

          ubahStatusSiswaNext(nisnSiswa);
        }
      } catch (e) {
        Get.snackbar('Error', 'periksa.. !! apakah wali kelas belum terisi..');
      }
    }
  }

}

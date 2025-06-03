import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class InputCatatanKhususSiswaController extends GetxController {

  var argumentKelas = Get.arguments;

  TextEditingController inputC = TextEditingController();
  TextEditingController judulC = TextEditingController();
  TextEditingController tindakanC = TextEditingController();

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

  Future<void> simpanCatatanSiswa() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
      String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    if (inputC.text.isNotEmpty &&
        idUser.isNotEmpty &&
        idSekolah.isNotEmpty &&
        emailAdmin.isNotEmpty &&
        // ignore: unnecessary_null_comparison
        idTahunAjaran != null) {
      
      
      // simpan info
     
     String kelas = argumentKelas['namakelas'];

      DateTime now = DateTime.now();
      String docIdInfoTahun = DateFormat.yMd().format(now).replaceAll('/', '-');

      // DateTime now = DateTime.now();
      String docIdInfoJamMenitDetik = DateFormat.Hms()
          .format(now)
          .replaceAll(':', '-');
      String docIdInfo = ("$docIdInfoTahun/$docIdInfoJamMenitDetik").replaceAll('/', '-');

      Query<Map<String, dynamic>> colPegawai = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('pegawai')
          .where('uid', isEqualTo: idUser);

      QuerySnapshot<Map<String, dynamic>> snapPegawai = await colPegawai.get();
      if (snapPegawai.docs.isNotEmpty) {
        Map<String, dynamic> dataPegawai = snapPegawai.docs.first.data();
        String namaPegawai = dataPegawai['alias'];
        String jabatan = dataPegawai['role'];


      Query<Map<String, dynamic>> colKepalaSekolah = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('pegawai')
          .where('role', isEqualTo: 'Kepala Sekolah');

      QuerySnapshot<Map<String, dynamic>> snapKepalaSekolah = await colKepalaSekolah.get();
      if (snapKepalaSekolah.docs.isNotEmpty) {
        Map<String, dynamic> dataKepalaSekolah = snapKepalaSekolah.docs.first.data();
        String idKepalaSekolah = dataKepalaSekolah['uid'];
        String namaKepalaSekolah = dataKepalaSekolah['alias'];

        // Simpan Guru BK
        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('pegawai')
            .doc(idUser)
            .collection('tahunajaran')
            .doc(idTahunAjaran)
            .set({
              'tahunajaran' : tahunajaranya,
            });


        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('pegawai')
            .doc(idUser)
            .collection('tahunajaran')
            .doc(idTahunAjaran)
            .collection('kelas')
            .doc(kelas)
            .set({
              'kelas' : kelas,
              'idKepalaSekolah' : idKepalaSekolah,
              'idwalikelas': argumentKelas['idwalikelas'],
              'walikelas': argumentKelas['walikelas'],
              'namaKepalaSekolah' : namaKepalaSekolah,
              'namapenginput' : namaPegawai,
              'jabatan' : jabatan,
              });

        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('pegawai')
            .doc(idUser)
            .collection('tahunajaran')
            .doc(idTahunAjaran)
            .collection('kelas')
            .doc(kelas)
            .collection('catatansiswa')
            .doc(docIdInfo)
            .set({
              'idpenginput': idUser,
              'idsekolah': idSekolah,
              'tahunajaran': idTahunAjaran,
              'idkepalasekolah': idKepalaSekolah,
              'namakepalasekolah': namaKepalaSekolah,
              'nisn': argumentKelas['nisn'],
              'namasiswa': argumentKelas['namasiswa'],
              'kelassiswa': kelas,
              'idwalikelas': argumentKelas['idwalikelas'],
              'walikelas': argumentKelas['walikelas'],
              'namapenginput': namaPegawai,
              'jabatanpenginput': jabatan,
              'emailadmin': emailAdmin,
              'judulinformasi': judulC.text,
              'informasicatatansiswa': inputC.text,
              'tindakangurubk' : tindakanC.text,
              'tanggapanwalikelas': "0",
              'tanggapankepalasekolah' : "0",
              'tanggapanorangtua':"0",
              'tanggalinput': now.toIso8601String(),
              'docId' : docIdInfo,
            });

        // Simpan waliKelas
        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('pegawai')
            .doc(argumentKelas['idwalikelas'])
            .collection('tahunajaran')
            .doc(idTahunAjaran)
            .set({
              'tahunajaran' : tahunajaranya,
            });


        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('pegawai')
            .doc(argumentKelas['idwalikelas'])
            .collection('tahunajaran')
            .doc(idTahunAjaran)
            .collection('kelas')
            .doc(kelas)
            .set({
              'kelas' : kelas,
              'idKepalaSekolah' : idKepalaSekolah,
              'idwalikelas': argumentKelas['idwalikelas'],
              'walikelas': argumentKelas['walikelas'],
              'namaKepalaSekolah' : namaKepalaSekolah,
              'namapenginput' : namaPegawai,
              'jabatan' : jabatan,
              });


        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('pegawai')
            .doc(argumentKelas['idwalikelas'])
            .collection('tahunajaran')
            .doc(idTahunAjaran)
            .collection('kelas')
            .doc(kelas)
            .collection('catatansiswa')
            .doc(docIdInfo)
            .set({
              'idpenginput': idUser,
              'idsekolah': idSekolah,
              'tahunajaran': idTahunAjaran,
              'idkepalasekolah': idKepalaSekolah,
              'namakepalasekolah': namaKepalaSekolah,
              'nisn': argumentKelas['nisn'],
              'namasiswa': argumentKelas['namasiswa'],
              'kelassiswa': kelas,
              'idwalikelas': argumentKelas['idwalikelas'],
              'walikelas': argumentKelas['walikelas'],
              'namapenginput': namaPegawai,
              'jabatanpenginput': jabatan,
              'emailadmin': emailAdmin,
              'judulinformasi': judulC.text,
              'informasicatatansiswa': inputC.text,
              'tindakangurubk' : tindakanC.text,
              'tanggapanwalikelas': "0",
              'tanggapankepalasekolah' : "0",
              'tanggapanorangtua':"0",
              'tanggalinput': now.toIso8601String(),
              'docId' : docIdInfo,
              });

          // Simpan kepala sekolah
          await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('pegawai')
            .doc(idKepalaSekolah)
            .collection('tahunajaran')
            .doc(idTahunAjaran)
            .set({
              'tahunajaran' : tahunajaranya,
            });


        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('pegawai')
            .doc(idKepalaSekolah)
            .collection('tahunajaran')
            .doc(idTahunAjaran)
            .collection('kelas')
            .doc(kelas)
            .set({
              'kelas' : kelas,
              'idKepalaSekolah' : idKepalaSekolah,
              'idwalikelas': argumentKelas['idwalikelas'],
              'walikelas': argumentKelas['walikelas'],
              'namaKepalaSekolah' : namaKepalaSekolah,
              'namapenginput' : namaPegawai,
              'jabatanpenginput' : jabatan,
              });


          await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('pegawai')
            .doc(idKepalaSekolah)
            .collection('tahunajaran')
            .doc(idTahunAjaran)
            .collection('kelas')
            .doc(kelas)
            .collection('catatansiswa')
            .doc(docIdInfo)
            .set({
              'idpenginput': idUser,
              'idsekolah': idSekolah,
              'tahunajaran': idTahunAjaran,
              'idkepalasekolah': idKepalaSekolah,
              'namakepalasekolah': namaKepalaSekolah,
              'nisn': argumentKelas['nisn'],
              'namasiswa': argumentKelas['namasiswa'],
              'kelassiswa': kelas,
              'idwalikelas': argumentKelas['idwalikelas'],
              'walikelas': argumentKelas['walikelas'],
              'namapenginput': namaPegawai,
              'jabatanpenginput': jabatan,
              'emailadmin': emailAdmin,
              'judulinformasi': judulC.text,
              'informasicatatansiswa': inputC.text,
              'tindakangurubk' : tindakanC.text,
              'tanggapanwalikelas': "0",
              'tanggapankepalasekolah' : "0",
              'tanggapanorangtua':"0",
              'tanggalinput': now.toIso8601String(),
              'docId' : docIdInfo,
            });

        // Simpan untuk Walimurid
        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('siswa')
            .doc(argumentKelas['nisn'])
            .collection('tahunajaran')
            .doc(idTahunAjaran)
            .collection('catatansiswa')
            .doc(docIdInfo)
            .set({
              'idpenginput': idUser,
              'idsekolah': idSekolah,
              'tahunajaran': idTahunAjaran,
              'idkepalasekolah': idKepalaSekolah,
              'namakepalasekolah': namaKepalaSekolah,
              'nisn': argumentKelas['nisn'],
              'namasiswa': argumentKelas['namasiswa'],
              'kelassiswa': kelas,
              'idwalikelas': argumentKelas['idwalikelas'],
              'walikelas': argumentKelas['walikelas'],
              'namapenginput': namaPegawai,
              'jabatanpenginput': jabatan,
              'emailadmin': emailAdmin,
              'judulinformasi': judulC.text,
              'informasicatatansiswa': inputC.text,
              'tindakangurubk' : tindakanC.text,
              'tanggapanwalikelas': "0",
              'tanggapankepalasekolah' : "0",
              'tanggapanorangtua':"0",
              'tanggalinput': now.toIso8601String(),
              'docId' : docIdInfo,
              });

      }

      Get.back();

      Get.snackbar(
        'Informasi',
        'Berhasil input Informasi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.grey[350],
      );

      refresh();


      }
    }
  }

  void test() {
    print(idSekolah);
    print(idUser);
    print(tindakanC.text);

  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class InputInfoSekolahController extends GetxController {
  TextEditingController inputC = TextEditingController();
  TextEditingController judulC = TextEditingController();

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

  void test() {
    DateTime now = DateTime.now();
      String docIdInfoTahun = DateFormat.yMd().format(now).replaceAll('/', '-');

    // DateTime now = DateTime.now();
      String docIdInfoJamMenitDetik = DateFormat.Hms().format(now).replaceAll(':', '-');
      String docIdInfo = ("$docIdInfoTahun/$docIdInfoJamMenitDetik").replaceAll('/', '-');

      print("docIdInfo = $docIdInfo");
  }

  Future<void> simpanInfo() async {
    if (inputC.text.isNotEmpty &&
        idUser.isNotEmpty &&
        idSekolah.isNotEmpty &&
        emailAdmin.isNotEmpty &&
        idTahunAjaran != null) {
      // simpan info
      DateTime now = DateTime.now();
      String docIdInfoTahun = DateFormat.yMd().format(now).replaceAll('/', '-');

    // DateTime now = DateTime.now();
      String docIdInfoJamMenitDetik = DateFormat.Hms().format(now).replaceAll(':', '-');
      String docIdInfo = ("$docIdInfoTahun/$docIdInfoJamMenitDetik").replaceAll('/', '-');

      Query<Map<String, dynamic>> colPegawai = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('pegawai')
          .where('uid', isEqualTo: idUser);

      QuerySnapshot<Map<String, dynamic>> snapPegawai = await colPegawai.get();
      if (snapPegawai.docs.isNotEmpty) {
        Map<String, dynamic> dataSemester = snapPegawai.docs.first.data();
        String namaPegawai = dataSemester['alias'];
        String jabatan = dataSemester['role'];

        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('tahunajaran')
            .doc(idTahunAjaran)
            .collection('informasisekolah')
            .doc(docIdInfo)
            .set({
              'iduser': idUser,
              'idsekolah': idSekolah,
              'namapenginput': namaPegawai,
              'jabatanpenginput': jabatan,
              'emailadmin': emailAdmin,
              'judulinformasi': judulC.text,
              'informasisekolah': inputC.text,
              'tanggalinput': now.toIso8601String(),
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

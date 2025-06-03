import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class DaftarSiswaPindahHalaqohController extends GetxController {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String idSekolah = '20404148';


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

  Future<String> getSemesterTerakhir() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");


    CollectionReference<Map<String, dynamic>> colSemester = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('semester');
    QuerySnapshot<Map<String, dynamic>> snapshotSemester=
        await colSemester.get();
    List<Map<String, dynamic>> listSemester =
        snapshotSemester.docs.map((e) => e.data()).toList();
    String semesterTerakhir =
        listSemester.map((e) => e['namasemester']).toList().last;
    return semesterTerakhir;
  }


 Future<QuerySnapshot<Map<String, dynamic>>> dataSiswaPindah() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    // String semesternya = await getSemesterTerakhir();

    return await firestore
        .collection('Sekolah')
         .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        // .collection('semester')
        // .doc(semesternya)
        .collection('riwayatpindahan')
        .orderBy('tanggalpindah', descending: true)
        .get();

    // print('ini get pentampunya = ${getPengampuNya.docs.first.data()['test']}');
    // return getDaftarSiswaPindahan;
  }

}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class DaftarNilaiController extends GetxController {
  var dataNilai = Get.arguments;

  FirebaseAuth auth = FirebaseAuth.instance;
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

  Future<QuerySnapshot<Map<String, dynamic>>> getDataNilai() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    CollectionReference<Map<String, dynamic>> colSemester = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelompokmengaji')
        .doc(dataNilai['fase'])
        .collection('pengampu')
        .doc(dataNilai['namapengampu'])
        .collection('tempat')
        .doc(dataNilai['tempatmengaji'])
        .collection('daftarsiswa')
        .doc(dataNilai['nisn'])
        .collection('semester');

    QuerySnapshot<Map<String, dynamic>> snapSemester = await colSemester.get();
    if (snapSemester.docs.isNotEmpty) {
      Map<String, dynamic> dataSemester = snapSemester.docs.first.data();
      String namaSemester = dataSemester['namasemester'];

      // String kelasnya = data.toString();
      return await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelompokmengaji')
          .doc(dataNilai['fase'])
          .collection('pengampu')
          .doc(dataNilai['namapengampu'])
          .collection('tempat')
          .doc(dataNilai['tempatmengaji'])
          .collection('daftarsiswa')
          .doc(dataNilai['nisn'])
          .collection('semester')
          .doc(namaSemester)
          .collection('nilai')
          .orderBy('tanggalinput', descending: true)
          .get();
    } else {
      throw Exception('Semester data not found');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class DetailSiswaController extends GetxController {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  var argumenNisn = Get.arguments;
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

  Future<QuerySnapshot<Map<String, dynamic>>> getDetailSiswa() async {

    return await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('siswa')
        .where('nisn', isEqualTo: argumenNisn)
        .get();
  }

}

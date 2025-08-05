import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../../modules/home/controllers/home_controller.dart';

class DaftarInformasiController extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();

  // Stream untuk mendapatkan SEMUA informasi, diurutkan dari yang terbaru.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllInformasiSekolah() {
    final idTahunAjaran = homeC.idTahunAjaran.value;
    if (idTahunAjaran == null) return const Stream.empty();

    return firestore
        .collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(idTahunAjaran)
        .collection('informasisekolah')
        .orderBy('tanggalinput', descending: true)
        .snapshots();
  }
}
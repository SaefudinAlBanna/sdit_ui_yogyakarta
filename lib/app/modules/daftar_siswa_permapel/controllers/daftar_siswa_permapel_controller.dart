// lib/app/modules/daftar_siswa_permapel/controllers/daftar_siswa_permapel_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../../modules/home/controllers/home_controller.dart'; // Import HomeController

class DaftarSiswaPermapelController extends GetxController {

  // --- DEPENDENSI ---
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();

  // --- ARGUMEN (diambil sekali saat inisialisasi) ---
  late String idKelas;
  late String namaMapel;
  
  // --- STATE MANAGEMENT ---
  final RxBool isLoading = true.obs;
  final RxList<Map<String, dynamic>> daftarSiswa = <Map<String, dynamic>>[].obs;
  final RxString appBarTitle = "Memuat...".obs;

  @override
  void onInit() {
    super.onInit();
    // Ambil argumen yang dikirim dari halaman sebelumnya
    final Map<String, dynamic> args = Get.arguments;
    idKelas = args['idKelas'];
    namaMapel = args['namaMapel'];

    // Set judul AppBar secara dinamis
    appBarTitle.value = '$namaMapel - Kelas ${idKelas.split('-').first}';

    // Mulai ambil data siswa
    fetchDataSiswa();
  }

  /// Mengambil daftar siswa dari Firestore
  Future<void> fetchDataSiswa() async {
    try {
      isLoading.value = true;
      daftarSiswa.clear();

      String idTahunAjaran = homeC.idTahunAjaran.value!;
      String idSekolah = homeC.idSekolah;
      
      // Path di firestore harus benar. Berdasarkan controller lama:
      // Sekolah -> idSekolah -> tahunajaran -> idTahunAjaran -> kelastahunajaran -> idKelas -> daftarsiswa
      final snapshot = await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelastahunajaran')
          .doc(idKelas)
          .collection('daftarsiswa')
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Simpan data dan ID dokumennya
        final listSiswa = snapshot.docs.map((doc) {
          var data = doc.data();
          data['idSiswa'] = doc.id; // <-- Simpan ID siswa untuk navigasi
          return data;
        }).toList();
        daftarSiswa.assignAll(listSiswa);
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal mengambil data siswa: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
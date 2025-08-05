import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../daftar_ekskul/controllers/daftar_ekskul_controller.dart';

class InputEkskulController extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String idSekolah = '20404148'; // Sesuaikan

  // Data siswa dan referensi lainnya dari argumen
  late Map<String, dynamic> dataSiswa;
  late String idSiswa;
  late String idKelas;

  var isLoading = true.obs;
  var isSaving = false.obs;

  var masterEkskul = <String>[].obs;
  var ekskulTerpilih = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    // REVISI: Ambil semua data yang dibutuhkan dari argumen
    dataSiswa = Get.arguments as Map<String, dynamic>;
    idSiswa = dataSiswa['id_siswa'];
    idKelas = dataSiswa['id_kelas'];
    
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    isLoading.value = true;
    try {
      final ekskulSnapshot = await firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('ekstrakurikuler') // Path ke master ekskul
          .get();
      masterEkskul.value = ekskulSnapshot.docs.map((doc) => doc['nama'] as String).toList();

      if (dataSiswa['daftar_ekskul'] != null) {
        ekskulTerpilih.value = List<String>.from(dataSiswa['daftar_ekskul']);
      }

    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void toggleEkskul(String namaEkskul) {
    if (ekskulTerpilih.contains(namaEkskul)) {
      ekskulTerpilih.remove(namaEkskul);
    } else {
      ekskulTerpilih.add(namaEkskul);
    }
    update(); // Bisa gunakan update() atau .value untuk Obx
  }

  // REVISI: Menyimpan data ke path Firestore yang benar
  // Future<void> simpanPerubahan() async {
  //   isSaving.value = true;
  //   try {
  //     // String idTahunAjaran = Get.find<DaftarEkskulController>().activeTahunAjaranId;
      
  //     // Path yang benar ke dokumen siswa
  //     await firestore
  //         .collection('Sekolah').doc(idSekolah)
  //         .collection('tahunajaran').doc(idTahunAjaran)
  //         .collection('kelastahunajaran').doc(idKelas)
  //         .collection('daftarsiswa').doc(idSiswa)
  //         .update({
  //           'daftar_ekskul': ekskulTerpilih.toList(),
  //     });

  //     Get.back(); // Kembali & memicu callback .then() di controller sebelumnya
  //     Get.snackbar(
  //       'Sukses', 
  //       'Data ekskul ${dataSiswa['nama']} berhasil diperbarui.',
  //       snackPosition: SnackPosition.BOTTOM,
  //     );
      
  //   } catch (e) {
  //     Get.snackbar('Error', 'Gagal menyimpan data: $e');
  //   } finally {
  //     isSaving.value = false;
  //   }
  // }
}
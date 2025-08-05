import 'package:get/get.dart';
import 'package:sdit_ui_yogyakarta/app/modules/home/controllers/home_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/siswa_model.dart';

// Model untuk menampung data satu baris di tabel rapor
class RaporEkskulItem {
  String namaEkskul;
  String? predikat;
  String? keterangan;

  RaporEkskulItem({required this.namaEkskul, this.predikat, this.keterangan});
}

class RaporEkskulViewController extends GetxController {
  final SiswaModel siswa;
  RaporEkskulViewController({required this.siswa});

  final HomeController homeC = Get.find<HomeController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxBool isLoading = true.obs;
  final RxList<RaporEkskulItem> daftarNilaiEkskul = <RaporEkskulItem>[].obs;
  // State untuk data absensi (akan kita tarik dari modul lain)
  final RxMap<String, int> rekapAbsensi = <String, int>{}.obs;
  
  @override
  void onInit() {
    super.onInit();
    generateRaporData();
  }

  Future<void> generateRaporData() async {
    isLoading.value = true;
    try {
      final idSekolah = homeC.idSekolah;
      final idTahunAjaran = homeC.idTahunAjaran.value!;
      final semesterField = "nilaiSemester${homeC.semesterAktifId.value}";

      // 1. Ambil daftar ekskul yang diikuti siswa dari koleksi siswa
      final ekskulDiikutiSnapshot = await _firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('siswa').doc(siswa.nisn)
          .collection('ekskul_diikuti')
          .where('idTahunAjaran', isEqualTo: idTahunAjaran)
          .get();
      
      final List<RaporEkskulItem> hasilRapor = [];

      // 2. Loop untuk setiap ekskul yang diikuti
      for (final doc in ekskulDiikutiSnapshot.docs) {
        final idInstanceEkskul = doc.id;
        
        // Ambil info nama master ekskul
        final masterRef = doc.data()['masterEkskulRef'];
        final masterDoc = await _firestore.collection('master_ekskul').doc(masterRef).get();
        final namaMaster = masterDoc.data()?['namaMaster'] ?? 'Ekskul';
        
        // Ambil data nilai dari sub-koleksi anggota di ekskul terkait
        final nilaiDoc = await _firestore
            .collection('Sekolah').doc(idSekolah)
            .collection('tahunajaran').doc(idTahunAjaran)
            .collection('ekstrakurikuler').doc(idInstanceEkskul)
            .collection('anggota').doc(siswa.nisn)
            .get();
        
        String? predikat;
        String? keterangan;
        if (nilaiDoc.exists && nilaiDoc.data()!.containsKey(semesterField)) {
          final nilaiData = nilaiDoc.data()![semesterField];
          predikat = nilaiData['predikat'];
          keterangan = nilaiData['keterangan'];
        }

        hasilRapor.add(RaporEkskulItem(
          namaEkskul: namaMaster,
          predikat: predikat,
          keterangan: keterangan,
        ));
      }

      daftarNilaiEkskul.value = hasilRapor;
      
      // (Placeholder) Di sini nanti Anda akan memanggil fungsi untuk mengambil data absensi KBM siswa
      // await fetchAbsensiSiswa();

    } catch (e) {
      Get.snackbar("Error", "Gagal mengambil data rapor: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
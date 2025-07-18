import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';

class DaftarEkskulController extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String idSekolah = '20404148'; // Sesuaikan

  var isLoading = false.obs;
  var isSiswaLoading = false.obs;

  var daftarKelas = <String>[].obs;
  var selectedKelas = Rxn<String>();

  var daftarSiswa = <QueryDocumentSnapshot<Map<String, dynamic>>>[].obs;
  
  // Variabel untuk menyimpan ID tahun ajaran aktif
  late String activeTahunAjaranId;

  @override
  void onInit() {
    super.onInit();
    fetchDaftarKelas();
  }

  // REVISI: Mengambil daftar kelas dari koleksi 'kelastahunajaran'
  Future<void> fetchDaftarKelas() async {
    isLoading.value = true;
    try {
      activeTahunAjaranId = await getTahunAjaranTerakhir();
      final kelasSnapshot = await firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(activeTahunAjaranId)
          .collection('kelastahunajaran')
          .get();

      // ID dari setiap dokumen adalah nama kelasnya
      daftarKelas.value = kelasSnapshot.docs.map((doc) => doc.id).toList()..sort();
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengambil daftar kelas: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // REVISI: Mengambil siswa dari sub-koleksi 'daftarsiswa' di dalam kelas yang dipilih
  Future<void> fetchSiswaByKelas(String idKelas) async {
    isSiswaLoading.value = true;
    selectedKelas.value = idKelas;
    daftarSiswa.clear(); // Kosongkan list sebelum fetch data baru
    try {
      final siswaSnapshot = await firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(activeTahunAjaranId)
          .collection('kelastahunajaran').doc(idKelas)
          .collection('daftarsiswa')
          .get();

      daftarSiswa.value = siswaSnapshot.docs;
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengambil data siswa: $e');
    } finally {
      isSiswaLoading.value = false;
    }
  }

  // REVISI: Mengirim data siswa beserta ID kelasnya ke halaman input
  void goToInputEkskul(QueryDocumentSnapshot<Map<String, dynamic>> siswaDoc) {
    Map<String, dynamic> args = siswaDoc.data();
    args['id_siswa'] = siswaDoc.id; // ID siswa dari dokumen
    args['id_kelas'] = selectedKelas.value; // ID kelas yang sedang aktif

    Get.toNamed(Routes.INPUT_EKSKUL, arguments: args)?.then((_) {
      // Callback ini akan dijalankan saat halaman input ditutup (Get.back())
      // Kita refresh data untuk menampilkan perubahan ekskul terbaru
      if (selectedKelas.value != null) {
        fetchSiswaByKelas(selectedKelas.value!);
      }
    });
  }

  Future<String> getTahunAjaranTerakhir() async {
    QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran')
        .orderBy('namatahunajaran', descending: true)
        .limit(1).get();
    if (snapshot.docs.isEmpty) throw Exception("Tidak ada data tahun ajaran");
    return snapshot.docs.first.id;
  }
}
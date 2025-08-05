import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../home/controllers/home_controller.dart'; // [PENTING]
import '../../../routes/app_pages.dart';

class DaftarEkskulController extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>(); // [PENTING]

  var isLoading = true.obs;
  var isSiswaLoading = false.obs;

  var daftarKelas = <String>[].obs;
  var selectedKelas = Rxn<String>();
  
  // [MODIFIKASI] Kita simpan data siswa dan ekskulnya dalam satu Map
  var daftarSiswaDenganEkskul = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchDaftarKelas();
  }

  Future<void> fetchDaftarKelas() async {
    isLoading.value = true;
    try {
      // [PERBAIKAN] Ambil tahun ajaran dari HomeController, bukan query baru
      final idTahunAjaran = homeC.idTahunAjaran.value;
      if (idTahunAjaran == null) throw Exception("Tahun ajaran tidak aktif");

      final kelasSnapshot = await firestore
          .collection('Sekolah').doc(homeC.idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelastahunajaran').get();

      daftarKelas.value = kelasSnapshot.docs.map((doc) => doc.id).toList()..sort();
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengambil daftar kelas: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // [DIROMBAK TOTAL] Mengambil siswa DAN data ekskul yang mereka ikuti
  Future<void> fetchSiswaDanEkskul(String idKelas) async {
    isSiswaLoading.value = true;
    selectedKelas.value = idKelas;
    daftarSiswaDenganEkskul.clear();
    
    try {
      final idTahunAjaran = homeC.idTahunAjaran.value!;
      final semester = homeC.semesterAktifId.value;

      final siswaSnapshot = await firestore
          .collection('Sekolah').doc(homeC.idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelastahunajaran').doc(idKelas)
          .collection('semester').doc(semester)
          .collection('daftarsiswa').get();

      List<Map<String, dynamic>> tempList = [];
      for (var siswaDoc in siswaSnapshot.docs) {
        final siswaData = siswaDoc.data();
        siswaData['uid'] = siswaDoc.id; // Pastikan UID ada

        // Query Collection Group untuk mencari tahu ekskul mana yang diikuti siswa ini
        final ekskulSnapshot = await firestore
            .collectionGroup('anggota')
            .where('uid', isEqualTo: siswaDoc.id)
            .get();
        
        // Ambil nama ekskul dari path parent
        final List<String> ekskulDiikuti = ekskulSnapshot.docs.map((doc) => doc.reference.parent.parent!.id).toList();
        
        // Ambil nama ekskulnya untuk ditampilkan
         final List<Map<String, dynamic>> ekskulDataDiikuti = [];
          for (var doc in ekskulSnapshot.docs) {
            final ekskulParentDoc = await doc.reference.parent.parent!.get();
            ekskulDataDiikuti.add(ekskulParentDoc.data() as Map<String, dynamic>);
          }


        siswaData['daftar_ekskul'] = ekskulDataDiikuti.map((e) => e['namaEkskul']).toList();
        tempList.add(siswaData);
      }
      daftarSiswaDenganEkskul.assignAll(tempList);

    } catch (e) {
      Get.snackbar('Error', 'Gagal mengambil data siswa: $e');
    } finally {
      isSiswaLoading.value = false;
    }
  }

  // Navigasi ke halaman input yang baru
  void goToInputEkskul(Map<String, dynamic> siswaData) {
    Get.toNamed(Routes.INPUT_EKSKUL, arguments: siswaData)?.then((_) {
      if (selectedKelas.value != null) {
        fetchSiswaDanEkskul(selectedKelas.value!);
      }
    });
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';
// import '../../../routes/app_pages.dart';

// class DaftarEkskulController extends GetxController {
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;
//   final String idSekolah = '20404148';

//   var isLoading = false.obs;
//   var isSiswaLoading = false.obs;

//   var daftarKelas = <String>[].obs;
//   var selectedKelas = Rxn<String>();

//   var daftarSiswa = <QueryDocumentSnapshot<Map<String, dynamic>>>[].obs;
  
//   // Variabel untuk menyimpan ID tahun ajaran aktif
//   late String activeTahunAjaranId;

//   @override
//   void onInit() {
//     super.onInit();
//     fetchDaftarKelas();
//   }

//   // REVISI: Mengambil daftar kelas dari koleksi 'kelastahunajaran'
//   Future<void> fetchDaftarKelas() async {
//     isLoading.value = true;
//     try {
//       activeTahunAjaranId = await getTahunAjaranTerakhir();
//       final kelasSnapshot = await firestore
//           .collection('Sekolah').doc(idSekolah)
//           .collection('tahunajaran').doc(activeTahunAjaranId)
//           .collection('kelastahunajaran')
//           .get();

//       // ID dari setiap dokumen adalah nama kelasnya
//       daftarKelas.value = kelasSnapshot.docs.map((doc) => doc.id).toList()..sort();
//     } catch (e) {
//       Get.snackbar('Error', 'Gagal mengambil daftar kelas: $e');
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   // REVISI: Mengambil siswa dari sub-koleksi 'daftarsiswa' di dalam kelas yang dipilih
//   Future<void> fetchSiswaByKelas(String idKelas) async {
//     isSiswaLoading.value = true;
//     selectedKelas.value = idKelas;
//     daftarSiswa.clear(); // Kosongkan list sebelum fetch data baru
//     try {
//       final siswaSnapshot = await firestore
//           .collection('Sekolah').doc(idSekolah)
//           .collection('tahunajaran').doc(activeTahunAjaranId)
//           .collection('kelastahunajaran').doc(idKelas)
//           .collection('daftarsiswa')
//           .get();

//       daftarSiswa.value = siswaSnapshot.docs;
//     } catch (e) {
//       Get.snackbar('Error', 'Gagal mengambil data siswa: $e');
//     } finally {
//       isSiswaLoading.value = false;
//     }
//   }

//   // REVISI: Mengirim data siswa beserta ID kelasnya ke halaman input
//   void goToInputEkskul(QueryDocumentSnapshot<Map<String, dynamic>> siswaDoc) {
//     Map<String, dynamic> args = siswaDoc.data();
//     args['id_siswa'] = siswaDoc.id; // ID siswa dari dokumen
//     args['id_kelas'] = selectedKelas.value; // ID kelas yang sedang aktif

//     Get.toNamed(Routes.INPUT_EKSKUL, arguments: args)?.then((_) {
//       // Callback ini akan dijalankan saat halaman input ditutup (Get.back())
//       // Kita refresh data untuk menampilkan perubahan ekskul terbaru
//       if (selectedKelas.value != null) {
//         fetchSiswaByKelas(selectedKelas.value!);
//       }
//     });
//   }

//   Future<String> getTahunAjaranTerakhir() async {
//     QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
//         .collection('Sekolah').doc(idSekolah)
//         .collection('tahunajaran')
//         .orderBy('namatahunajaran', descending: true)
//         .limit(1).get();
//     if (snapshot.docs.isEmpty) throw Exception("Tidak ada data tahun ajaran");
//     return snapshot.docs.first.id;
//   }
// }
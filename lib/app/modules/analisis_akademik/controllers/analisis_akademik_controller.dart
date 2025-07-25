// lib/app/modules/analisis_akademik/controllers/analisis_akademik_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../home/controllers/home_controller.dart';
import '../../../models/analisis_akademik_model.dart';

class AnalisisAkademikController extends GetxController {
  // --- DEPENDENSI & DATA DASAR ---
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();
  String? idKelas;
  late String idTahunAjaran;
  late String semesterAktif;

  // --- STATE MANAGEMENT ---
  final RxBool isLoading = false.obs;
  // State ini tetap kita gunakan untuk memberitahu View
  final RxBool isDataAvailable = false.obs; 
  final Rxn<KelasAkademikModel> hasilAnalisis = Rxn<KelasAkademikModel>();
  
  bool get isAdmin => homeC.userRole.value == 'Admin';

  @override
  void onReady() {
    super.onReady();
    loadAndAnalyzeData();
  }

  Future<void> loadAndAnalyzeData() async {
    if (idKelas == null) return;

    isLoading.value = true;
    hasilAnalisis.value = null;
    isDataAvailable.value = false; // Selalu reset di awal

    try {
      // LANGKAH 1: Ambil daftar lengkap siswa di kelas ini (ini sudah benar)
      final siswaSnapshot = await firestore
          .collection('Sekolah').doc(homeC.idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelastahunajaran').doc(idKelas!)
          .collection('semester').doc(semesterAktif)
          .collection('daftarsiswa').get();

      // --- KUNCI UTAMA: Gunakan hasil query siswa sebagai penentu ---
      if (siswaSnapshot.docs.isEmpty) {
        // Jika tidak ada SISWA, maka tidak ada data akademik untuk ditampilkan.
        isDataAvailable.value = false;
        isLoading.value = false;
        return; // Hentikan proses
      }
      
      // Jika kita sampai di sini, artinya ADA SISWA, maka data dianggap TERSEDIA.
      isDataAvailable.value = true;

      // Sisa dari logika Anda untuk menganalisis data sudah SANGAT BAIK dan tidak perlu diubah.
      // Kita hanya perlu memastikan ia berjalan setelah pengecekan di atas.
      List<SiswaAkademikModel> daftarSiswaHasil = [];
      double totalSemuaNilai = 0;
      int jumlahSemuaNilai = 0;

      for (var siswaDoc in siswaSnapshot.docs) {
        final idSiswa = siswaDoc.id;
        final namaSiswa = siswaDoc.data()['namasiswa'] ?? 'Tanpa Nama';
        final mapelSnapshot = await siswaDoc.reference.collection('matapelajaran').get();

        List<double> listNilaiSiswa = [];
        if (mapelSnapshot.docs.isNotEmpty) {
          for (var mapelDoc in mapelSnapshot.docs) {
            final nilai = mapelDoc.data()['nilai_akhir'];
            if (nilai != null && nilai is num) {
              listNilaiSiswa.add(nilai.toDouble());
            }
          }
        }

        double rataRataSiswa = listNilaiSiswa.isEmpty ? 0.0 : listNilaiSiswa.reduce((a, b) => a + b) / listNilaiSiswa.length;
        daftarSiswaHasil.add(SiswaAkademikModel(idSiswa: idSiswa, namaSiswa: namaSiswa, rataRataNilai: rataRataSiswa));

        if (listNilaiSiswa.isNotEmpty) {
          totalSemuaNilai += listNilaiSiswa.reduce((a, b) => a + b);
        }
        jumlahSemuaNilai += listNilaiSiswa.length;
      }

      daftarSiswaHasil.sort((a, b) => (b.rataRataNilai ?? 0).compareTo(a.rataRataNilai ?? 0));
      double rataRataKelas = jumlahSemuaNilai == 0 ? 0.0 : totalSemuaNilai / jumlahSemuaNilai;

      hasilAnalisis.value = KelasAkademikModel(
        rataRataKelas: rataRataKelas,
        daftarSiswa: daftarSiswaHasil,
      );

    } catch (e) {
      Get.snackbar("Error Analisis", "Gagal memproses data akademik: $e");
      isDataAvailable.value = false; // Jika ada error, anggap data tidak tersedia
    } finally {
      isLoading.value = false;
    }
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';
// import '../../home/controllers/home_controller.dart';
// import '../../../models/analisis_akademik_model.dart';

// class AnalisisAkademikController extends GetxController {
//   // --- DEPENDENSI & DATA DASAR ---
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;
//   final HomeController homeC = Get.find<HomeController>();
//   String? idKelas;
//   late String idTahunAjaran;
//   late String semesterAktif;
//   // --- STATE MANAGEMENT ---
//   final RxBool isDataAvailable = false.obs;
//   final RxBool isLoading = false.obs;
//   // Gunakan Rxn (nullable Rx) untuk menampung hasil analisis
//   final Rxn<KelasAkademikModel> hasilAnalisis = Rxn<KelasAkademikModel>();
//   // NOTE: Kita tidak perlu onInit() karena controller ini akan diinisialisasi
//   // dan datanya akan di-"suntik" oleh DaftarKelasController.
//   // Tapi, kita butuh fungsi yang bisa dipanggil untuk memulai proses.
//   /// Fungsi utama yang akan dipanggil untuk memuat dan menganalisis data.
  
//   bool get isAdmin => homeC.userRole.value == 'Admin' || homeC.userRole.value == 'Kepala Sekolah';

//   Future<void> loadAndAnalyzeData() async {
//     if (idKelas == null) return;
//     isLoading.value = true;
//     hasilAnalisis.value = null;
//     isDataAvailable.value = false; // Reset ke false setiap kali loading

//     try {
//       final siswaSnapshot = await firestore.collection('Sekolah').doc(homeC.idSekolah)
//           .collection('tahunajaran').doc(idTahunAjaran)
//           .collection('kelastahunajaran').doc(idKelas!)
//           .collection('semester').doc(semesterAktif)
//           .collection('daftarsiswa').get();

//       // --- KUNCI UTAMA: Cek apakah ada siswa di kelas ini ---
//       if (siswaSnapshot.docs.isEmpty) {
//         // Jika tidak ada siswa, langsung set data tidak tersedia dan berhenti.
//         isDataAvailable.value = false;
//         isLoading.value = false;
//         return;
//       }
      
//       // Jika ada siswa, lanjutkan proses analisis...
//       isDataAvailable.value = true; // Set data tersedia
      
//       List<SiswaAkademikModel> daftarSiswaHasil = [];
//       double totalSemuaNilai = 0;
//       int jumlahSemuaNilai = 0;

//       for (var siswaDoc in siswaSnapshot.docs) {
//         final idSiswa = siswaDoc.id;
//         final namaSiswa = siswaDoc.data()['namasiswa'] ?? 'Tanpa Nama';
//         final mapelSnapshot = await siswaDoc.reference.collection('matapelajaran').get();

//         List<double> listNilaiSiswa = [];
//         if (mapelSnapshot.docs.isNotEmpty) {
//           for (var mapelDoc in mapelSnapshot.docs) {
//             final nilai = mapelDoc.data()['nilai_akhir'];
//             if (nilai != null && nilai is num) {
//               listNilaiSiswa.add(nilai.toDouble());
//             }
//           }
//         }

//         double rataRataSiswa = listNilaiSiswa.isEmpty ? 0.0 : listNilaiSiswa.reduce((a, b) => a + b) / listNilaiSiswa.length;
//         daftarSiswaHasil.add(SiswaAkademikModel(idSiswa: idSiswa, namaSiswa: namaSiswa, rataRataNilai: rataRataSiswa));

//         if (listNilaiSiswa.isNotEmpty) {
//           totalSemuaNilai += listNilaiSiswa.reduce((a, b) => a + b);
//         }
//         jumlahSemuaNilai += listNilaiSiswa.length;
//       }

//       daftarSiswaHasil.sort((a, b) => (b.rataRataNilai ?? 0).compareTo(a.rataRataNilai ?? 0));
//       double rataRataKelas = jumlahSemuaNilai == 0 ? 0.0 : totalSemuaNilai / jumlahSemuaNilai;

//       hasilAnalisis.value = KelasAkademikModel(
//         rataRataKelas: rataRataKelas,
//         daftarSiswa: daftarSiswaHasil,
//       );

//     } catch (e) {
//       // Menangkap error "Bad state: No element" jika terjadi di tempat lain
//       if (e.toString().contains("Bad state: No element")) {
//         isDataAvailable.value = false;
//       } else {
//         Get.snackbar("Error Analisis", "Gagal memproses data akademik: $e");
//       }
//     } finally {
//       isLoading.value = false;
//     }
//   }
// }


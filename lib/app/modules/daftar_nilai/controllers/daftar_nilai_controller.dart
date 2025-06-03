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

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';

// class DaftarNilaiController extends GetxController {
//   late Map<String, dynamic> dataSiswaArgs;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   static const String _defaultIdSekolah = '20404148'; // Pertimbangkan untuk membuatnya konfigurasi

//   // Getter untuk idSekolah agar lebih bersih
//   String get idSekolah {
//     // Pastikan dataSiswaArgs sudah diinisialisasi
//     if (dataSiswaArgs.containsKey('id_sekolah') && dataSiswaArgs['id_sekolah'] != null) {
//       return dataSiswaArgs['id_sekolah'] as String;
//     }
//     return _defaultIdSekolah;
//   }

//   // State untuk UI
//   final RxBool isLoading = true.obs;
//   final RxString errorMessage = ''.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     final arguments = Get.arguments;
//     print("DaftarNilaiController - Arguments Diterima: $arguments");
//     if (arguments is Map<String, dynamic>) {
//       dataSiswaArgs = arguments;
//       print("DaftarNilaiController - dataSiswaArgs: $dataSiswaArgs");
//       print("DaftarNilaiController - ID Sekolah Digunakan: $idSekolah");
//       // JANGAN panggil streamDataNilai() di sini, biarkan StreamBuilder yang memanggil
//     } else {
//       dataSiswaArgs = {};
//       errorMessage.value = "Data siswa tidak valid untuk menampilkan nilai.";
//       isLoading.value = false; // Langsung set false karena tidak bisa lanjut
//       print("DaftarNilaiController - Argumen TIDAK VALID, isLoading: ${isLoading.value}, errorMessage: ${errorMessage.value}");
//     }
//   }

//   // Fungsi helper untuk mendapatkan tahun ajaran terakhir
//   Future<String> _fetchTahunAjaranTerakhir() async {
//   print("_fetchTahunAjaranTerakhir: Memulai untuk ID Sekolah: $idSekolah");
//   try {
//     QuerySnapshot<Map<String, dynamic>> snapshotTahunAjaran = await _firestore
//         .collection('Sekolah')
//         .doc(idSekolah)
//         .collection('tahunajaran')
//         .orderBy('timestamp_pembuatan_ta', descending: true)
//         .limit(1)
//         .get();

//     if (snapshotTahunAjaran.docs.isNotEmpty) {
//       final namaTA = snapshotTahunAjaran.docs.first.data()['namatahunajaran'] as String?;
//       print("_fetchTahunAjaranTerakhir: Sukses - Dokumen ditemukan, namaTA: $namaTA");
//       if (namaTA != null) return namaTA;
//     }
//     print("_fetchTahunAjaranTerakhir: Gagal - Tidak ada dokumen tahun ajaran atau namaTA null.");
//     throw Exception("Tahun ajaran terakhir tidak ditemukan.");
//   } catch (e) {
//     print("_fetchTahunAjaranTerakhir: Error Catch - $e");
//     throw Exception("Gagal mendapatkan data tahun ajaran: ${e.toString()}");
//   }
// }

//   // Fungsi helper untuk mendapatkan nama semester siswa
//   Future<String> _fetchNamaSemesterSiswa(String idTahunAjaranFormatted) async {
//   print("_fetchNamaSemesterSiswa: Memulai untuk TA Formatted: $idTahunAjaranFormatted");
//   print("_fetchNamaSemesterSiswa - Menggunakan dataSiswaArgs: $dataSiswaArgs");
//   if (dataSiswaArgs.isEmpty) {
//     print("_fetchNamaSemesterSiswa: Error - dataSiswaArgs tidak lengkap.");
//     throw Exception("Data siswa tidak lengkap untuk mengambil semester.");
//   }
//   try {
//     // ... (query Firestore seperti sebelumnya) ...
//     QuerySnapshot<Map<String, dynamic>> snapSemester = await _firestore
//         .collection('Sekolah').doc(idSekolah)
//         .collection('tahunajaran').doc(idTahunAjaranFormatted)
//         .collection('kelompokmengaji').doc(dataSiswaArgs['fase'] as String)
//         .collection('pengampu').doc(dataSiswaArgs['namapengampu'] as String)
//         .collection('tempat').doc(dataSiswaArgs['tempatmengaji'] as String)
//         .collection('daftarsiswa').doc(dataSiswaArgs['nisn'] as String)
//         .collection('semester')
//         .orderBy('tanggalinput', descending: true) // PERIKSA FIELD INI!
//         .limit(1)
//         .get();

//     if (snapSemester.docs.isNotEmpty) {
//       final namaSemester = snapSemester.docs.first.data()['namasemester'] as String?;
//       print("_fetchNamaSemesterSiswa: Sukses - Dokumen ditemukan, namaSemester: $namaSemester");
//       if (namaSemester != null) return namaSemester;
//     }
//     print("_fetchNamaSemesterSiswa: Gagal - Tidak ada dokumen semester atau namaSemester null.");
//     throw Exception("Semester siswa tidak ditemukan.");
//   } catch (e) {
//     print("_fetchNamaSemesterSiswa: Error Catch - $e");
//     throw Exception("Gagal mendapatkan data semester siswa: ${e.toString()}");
//   }
// }

//   // Fungsi utama untuk mendapatkan stream nilai
//    Stream<QuerySnapshot<Map<String, dynamic>>> streamDataNilai() async* {
//     // Set isLoading true DI AWAL FUNGSI STREAM INI
//     // Ini akan ditangkap oleh Obx jika StreamBuilder belum sempat menampilkan loadingnya sendiri
//     isLoading.value = true;
//     errorMessage.value = '';
//     print("DaftarNilaiController - streamDataNilai: Memulai. isLoading: ${isLoading.value}");

//     if (dataSiswaArgs.isEmpty || dataSiswaArgs['fase'] == null) {
//       final String errorMsg = "Informasi siswa tidak lengkap untuk memuat nilai.";
//       errorMessage.value = errorMsg;
//       isLoading.value = false; // Penting di jalur error
//       print("DaftarNilaiController - streamDataNilai: Error awal - dataSiswaArgs tidak valid. isLoading: ${isLoading.value}, error: ${errorMessage.value}");
//       yield* Stream.error(Exception(errorMsg));
//       return;
//     }

//     try {
//       print("DaftarNilaiController - streamDataNilai: Akan memanggil _fetchTahunAjaranTerakhir");
//       final String tahunAjaran = await _fetchTahunAjaranTerakhir();
//       print("DaftarNilaiController - streamDataNilai: Hasil _fetchTahunAjaranTerakhir: $tahunAjaran");
//       final String idTahunAjaranFormatted = tahunAjaran.replaceAll("/", "-");

//       print("DaftarNilaiController - streamDataNilai: Akan memanggil _fetchNamaSemesterSiswa dengan TA: $idTahunAjaranFormatted");
//       final String namaSemester = await _fetchNamaSemesterSiswa(idTahunAjaranFormatted);
//       print("DaftarNilaiController - streamDataNilai: Hasil _fetchNamaSemesterSiswa: $namaSemester");

//       print("DaftarNilaiController - streamDataNilai: Akan yield stream Firestore. isLoading saat ini (sebelum map): ${isLoading.value}");
//       // isLoading akan di-set false oleh .map() di bawah saat data pertama datang.
//       // Jika ada error sebelum itu, catch utama akan set isLoading = false.

//       yield* _firestore
//           // ... (path query Anda)
//           .collection('Sekolah').doc(idSekolah)
//           .collection('tahunajaran').doc(idTahunAjaranFormatted)
//           .collection('kelompokmengaji').doc(dataSiswaArgs['fase'] as String)
//           .collection('pengampu').doc(dataSiswaArgs['namapengampu'] as String)
//           .collection('tempat').doc(dataSiswaArgs['tempatmengaji'] as String)
//           .collection('daftarsiswa').doc(dataSiswaArgs['nisn'] as String)
//           .collection('semester').doc(namaSemester)
//           .collection('nilai')
//           .orderBy('tanggalinput', descending: true)
//           .snapshots()
//           .map((snapshot) {
//               if (isLoading.value) { // Hanya set sekali
//                   print("DaftarNilaiController - streamDataNilai (map): Data pertama dari Firestore, isLoading -> false. Jumlah Dokumen: ${snapshot.docs.length}");
//                   isLoading.value = false;
//               } else {
//                   print("DaftarNilaiController - streamDataNilai (map): Update data dari Firestore. Jumlah Dokumen: ${snapshot.docs.length}");
//               }
//               return snapshot;
//             })
//           .handleError((error, stackTrace){
//               print("DaftarNilaiController - streamDataNilai (handleError Firestore): Error: $error. isLoading -> false");
//               isLoading.value = false; // Pastikan di-set false
//               errorMessage.value = "Gagal memuat daftar nilai: ${error.toString()}";
//               throw Exception(errorMessage.value); // Rethrow agar StreamBuilder menangkapnya
//             });

//     } catch (e) {
//       print("DaftarNilaiController - streamDataNilai (catch utama): Error: $e. isLoading -> false");
//       isLoading.value = false; // Pastikan di-set false
//       errorMessage.value = e.toString().replaceFirst("Exception: ", "");
//       yield* Stream.error(Exception(errorMessage.value));
//     }
//     // Tidak perlu set isLoading false di sini jika stream berhasil, .map akan menanganinya.
//     // Jika stream selesai (tidak ada lagi data atau error), isLoading akan tetap false.
//   }

// }
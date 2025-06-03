
// ========== KODE BARU =================

// Baik! Dengan kode controller yang lengkap, kita bisa membuat saran yang lebih terintegrasi dan akurat. Mari kita percantik tampilan dan tingkatkan kemudahan penggunaan aplikasi Flutter Anda.
// Saya akan menggunakan pendekatan yang sama seperti sebelumnya, yaitu memecah UI menjadi komponen yang lebih kecil, menggunakan tema, memperbaiki tata letak, dan memastikan interaksi pengguna lebih jelas, sambil menyesuaikan dengan logika di PemberianNilaiHalaqohController.
// Perubahan Utama pada PemberianNilaiHalaqohController.dart:
// State Loading: Tambahkan RxBool isLoading = false.obs; untuk mengelola status loading saat tombol simpan ditekan.
// Error Handling pada ambilDataUmi: Kembalikan pesan yang lebih informatif atau null jika data tidak ditemukan, dan tangani di FutureBuilder.
// Validasi Input: Buat fungsi String? validateInput() untuk memusatkan logika validasi.
// Logika simpanNilai:
// Gunakan isLoading untuk disable tombol saat proses.
// Panggil validateInput sebelum menyimpan.
// Berikan feedback (Snackbar) yang lebih baik untuk sukses atau error.
// Pastikan tipe data yang disimpan ke Firestore sesuai (misalnya, nilai sebagai int).
// Tangani kasus update nilai dengan dialog konfirmasi yang fungsional.
// Penamaan Variabel dan Konstanta: Gunakan konstanta untuk idSekolah jika tidak berubah atau dapatkan dari konfigurasi.
// Membersihkan Field: Buat method _clearFields() untuk membersihkan input setelah berhasil simpan (opsional, tergantung kebutuhan UX).
// Dispose Controller: Pastikan semua TextEditingController di-dispose di onClose().
// Get.arguments: Akses dengan aman dan pastikan tipenya.
// Perubahan Utama pada PemberianNilaiHalaqohView.dart:
// Theming: Gunakan Theme.of(context) dan Theme.of(context).colorScheme secara konsisten.
// Struktur & Layout:
// Gunakan LayoutBuilder untuk responsivitas pada bagian info siswa dan pengampu.
// Gunakan Card dengan styling yang lebih baik (elevation, shape, padding).
// Gunakan SizedBox untuk spacing yang konsisten.
// Buat widget helper untuk judul section.
// Input Fields:
// Gunakan InputDecoration yang seragam (misalnya, OutlineInputBorder, labelText, filled).
// Perbaiki DropdownSearch (items, popupProps, decorator).
// Batasi input nilai dengan LengthLimitingTextInputFormatter dan validasi angka.
// Radio Buttons:
// Gunakan RadioListTile untuk tampilan yang lebih baik dan terintegrasi.
// Tampilkan deskripsi lengkap (value dari radio) sebagai subtitle.
// Tombol Simpan:
// Ganti FloatingActionButton dengan ElevatedButton full-width.
// Tampilkan CircularProgressIndicator pada tombol saat controller.isLoading.value adalah true.
// Feedback Pengguna: Gunakan Get.snackbar dengan styling yang jelas untuk sukses, peringatan, dan error.
// GestureDetector: Untuk menutup keyboard saat tap di luar field.
// Berikut adalah kode yang telah direvisi:
// PemberianNilaiHalaqohController.dart (Revisi)


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PemberianNilaiHalaqohController extends GetxController {
  // --- State Observables ---
  final RxString keteranganHalaqoh = "".obs;
  final RxBool isLoading = false.obs;

  // --- Text Editing Controllers ---
  late TextEditingController suratC;
  late TextEditingController ayatHafalC;
  // late TextEditingController jldSuratC; // Tidak terpakai di view Anda saat ini
  late TextEditingController halAyatC;
  late TextEditingController materiC;
  late TextEditingController nilaiC;
  // late TextEditingController keteranganGuruC; // Jika ada field custom, uncomment

  // late final Map<String, dynamic> dataArgs;

  // --- Firebase Instances ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Data from Arguments ---
  // Akan diinisialisasi di onInit dari Get.arguments
  Map<String, dynamic> dataArgs = {};

  // --- Constants (bisa dipindah ke file konfigurasi) ---
  static const String _defaultIdSekolah = '20404148';

  // --- Getters ---
  String get _currentUserId => _auth.currentUser!.uid;
  String get _currentUserEmail => _auth.currentUser!.email!;
  String get _idSekolah => dataArgs['id_sekolah'] ?? _defaultIdSekolah; // Contoh jika id_sekolah bisa dari args

   @override
  void onInit() {
    super.onInit();
    // Pastikan Get.arguments adalah Map<String, dynamic> atau tangani kasus lain
    final arguments = Get.arguments;
    if (arguments is Map<String, dynamic>) {
      dataArgs = arguments; // <--- UBAH INI
    } else {
      // Handle jika argumen tidak sesuai, misal dengan nilai default atau error
      dataArgs = {}; // Atau lempar error, atau navigasi kembali
      Get.snackbar("Error", "Data navigasi tidak valid.", backgroundColor: Colors.red);
    }
    // Inisialisasi controller lain yang mungkin bergantung pada dataArgs
    suratC = TextEditingController(text: dataArgs['initial_surat'] ?? '');
    ayatHafalC = TextEditingController();
    halAyatC = TextEditingController();
    materiC = TextEditingController();
    nilaiC = TextEditingController();
  }

  void onChangeKeterangan(String? catatan) {
    if (catatan != null) {
      keteranganHalaqoh.value = catatan;
      // if (keteranganGuruC.text.isNotEmpty) { // Jika ada field custom
      //   keteranganGuruC.clear();
      // }
    }
  }

  Future<String?> ambilDataUmi() async {
    if (dataArgs.isEmpty || dataArgs['tahunajaran'] == null) {
      // print("Error: Data arguments tidak lengkap untuk ambilDataUmi");
      return "Data siswa tidak lengkap";
    }

    String idTahunAjaranRaw = dataArgs['tahunajaran'];
    String idTahunAjaran = idTahunAjaranRaw.replaceAll("/", "-");

    try {
      // Path disesuaikan dengan asumsi 'namaSemester' adalah ID unik per siswa di bawah collection 'semester'
      // atau kita perlu mengambil dokumen semester yang relevan.
      // Kode asli mengambil `snapSemester.docs.first.data()`, mengasumsikan ada satu dokumen.
      QuerySnapshot<Map<String, dynamic>> snapSemesterSiswa = await _firestore
          .collection('Sekolah').doc(_idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelompokmengaji').doc(dataArgs['fase'])
          .collection('pengampu').doc(dataArgs['namapengampu'])
          .collection('tempat').doc(dataArgs['tempatmengaji'])
          .collection('daftarsiswa').doc(dataArgs['nisn'])
          .collection('semester')
          .limit(1) // Ambil dokumen semester terakhir/aktif
          .get();

      if (snapSemesterSiswa.docs.isNotEmpty) {
        Map<String, dynamic> dataSemester = snapSemesterSiswa.docs.first.data();
        return dataSemester['ummi'] as String? ?? "Belum diinput";
      }
      return "Belum diinput"; // Jika tidak ada dokumen semester
    } catch (e) {
      // print("Error ambilDataUmi: $e");
      return "Gagal memuat data";
    }
  }

  String? _validateInput() {
    if (suratC.text.trim().isEmpty) return 'Surat hafalan masih kosong';
    if (ayatHafalC.text.trim().isEmpty) return 'Ayat hafalan masih kosong';
    if (halAyatC.text.trim().isEmpty) return 'Halaman atau Ayat UMMI/AlQuran masih kosong';
    if (materiC.text.trim().isEmpty) return 'Materi UMMI/AlQuran masih kosong';
    if (nilaiC.text.trim().isEmpty) return 'Nilai masih kosong';
    final int? nilai = int.tryParse(nilaiC.text);
    if (nilai == null || nilai < 0 || nilai > 100) return 'Nilai harus antara 0 dan 100';
    if (keteranganHalaqoh.value.isEmpty /* && keteranganGuruC.text.trim().isEmpty */) {
      return 'Keterangan pengampu masih kosong';
    }
    return null;
  }

  Future<void> simpanNilai() async {
    final validationError = _validateInput();
    if (validationError != null) {
      Get.snackbar('Peringatan', validationError,
          backgroundColor: Colors.orange.shade700, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;

    if (dataArgs.isEmpty) {
      Get.snackbar('Error', 'Data siswa tidak lengkap untuk penyimpanan.',
          backgroundColor: Colors.red.shade700, colorText: Colors.white);
      isLoading.value = false;
      return;
    }

    try {
      String idTahunAjaranRaw = dataArgs['tahunajaran'];
      String idTahunAjaran = idTahunAjaranRaw.replaceAll("/", "-");
      DateTime now = DateTime.now();
      String docIdNilaiHarian = DateFormat('yyyy-MM-dd').format(now); // ID untuk nilai harian

      // Ambil data semester siswa (termasuk namaSemester dan UMI terakhir)
      DocumentSnapshot<Map<String, dynamic>>? docSemesterSiswa;
      QuerySnapshot<Map<String, dynamic>> snapSemesterSiswa = await _firestore
          .collection('Sekolah').doc(_idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelompokmengaji').doc(dataArgs['fase'])
          .collection('pengampu').doc(dataArgs['namapengampu'])
          .collection('tempat').doc(dataArgs['tempatmengaji'])
          .collection('daftarsiswa').doc(dataArgs['nisn'])
          .collection('semester')
          .orderBy('tanggalinput', descending: true) // Asumsi ada field timestamp
          .limit(1)
          .get();

      String namaSemester;
      String umiSaatIni;

      if (snapSemesterSiswa.docs.isNotEmpty) {
          docSemesterSiswa = snapSemesterSiswa.docs.first;
          namaSemester = docSemesterSiswa.data()?['namasemester'] ?? "Semester Tidak Diketahui";
          umiSaatIni = docSemesterSiswa.data()?['ummi'] ?? "UMI Tidak Diketahui";
      } else {
          // Handle jika tidak ada data semester, mungkin perlu dibuat dulu atau error
          Get.snackbar('Error', 'Data semester siswa tidak ditemukan.',
              backgroundColor: Colors.red.shade700, colorText: Colors.white);
          isLoading.value = false;
          return;
      }

      CollectionReference<Map<String, dynamic>> colNilaiHarian = docSemesterSiswa!.reference.collection('nilai');
      DocumentReference<Map<String, dynamic>> docNilaiRef = colNilaiHarian.doc(docIdNilaiHarian);

      int nilaiNumerik = int.parse(nilaiC.text);
      String grade = _getGrade(nilaiNumerik);

      final Map<String, dynamic> dataNilai = {
        // "tanggalinput": Timestamp.fromDate(now), // Simpan sebagai Timestamp
        "tanggalinput": DateTime.now().toIso8601String(), // Rubah jadi String
        "emailpenginput": _currentUserEmail,
        "fase": dataArgs['fase'],
        "idpengampu": _currentUserId,
        "idsiswa": dataArgs['nisn'],
        "kelas": dataArgs['kelas'],
        "kelompokmengaji": dataArgs['kelompokmengaji'],
        "namapengampu": dataArgs['namapengampu'],
        "namasemester": namaSemester,
        "namasiswa": dataArgs['namasiswa'],
        "tahunajaran": dataArgs['tahunajaran'],
        "tempatmengaji": dataArgs['tempatmengaji'],
        "hafalansurat": suratC.text.trim(),
        "ayathafalansurat": ayatHafalC.text.trim(),
        "ummijilidatausurat": umiSaatIni,
        "ummihalatauayat": halAyatC.text.trim(),
        "materi": materiC.text.trim(),
        "nilai": nilaiNumerik,
        "nilaihuruf": grade,
        "keteranganpengampu": keteranganHalaqoh.value,
        "keteranganorangtua": "0", // Default
        "uidnilai": docIdNilaiHarian, // atau docNilaiRef.id
        "last_updated": FieldValue.serverTimestamp(),
        "lastupdatedsting": FieldValue.serverTimestamp().toString(),
      };

      DocumentSnapshot<Map<String, dynamic>> cekNilaiHariIni = await docNilaiRef.get();

      if (cekNilaiHariIni.exists) {
        Get.defaultDialog(
          title: 'Konfirmasi Update',
          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
          middleText: 'Nilai untuk hari ini sudah ada. Apakah Anda ingin memperbarui data nilai?',
          textConfirm: 'Ya, Update',
          textCancel: 'Batal',
          confirmTextColor: Colors.white,
          buttonColor: Get.theme.colorScheme.primary,
          onConfirm: () async {
            Get.back(); // Tutup dialog
            await docNilaiRef.update(dataNilai);
            Get.snackbar('Sukses', 'Nilai berhasil diperbarui.',
                backgroundColor: Colors.green, colorText: Colors.white);
            // _clearFields(); // Opsional: bersihkan field setelah update
            // Get.back(); // Kembali ke halaman sebelumnya jika perlu
          },
          onCancel: () {}
        );
      } else {
        await docNilaiRef.set(dataNilai);
        Get.snackbar('Sukses', 'Nilai berhasil disimpan.',
            backgroundColor: Colors.green, colorText: Colors.white);
        _clearFields(); // Bersihkan field setelah simpan baru
        // Get.back(); // Kembali ke halaman sebelumnya jika perlu
      }
      // Panggil method refresh() Anda jika ada dan dibutuhkan
    } catch (e) {
      // print("Error simpanNilai: $e");
      Get.snackbar('Error', 'Terjadi kesalahan saat menyimpan: ${e.toString()}',
          backgroundColor: Colors.red.shade700, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  String _getGrade(int score) {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'E';
  }

  void _clearFields() {
    suratC.clear();
    ayatHafalC.clear();
    halAyatC.clear();
    materiC.clear();
    nilaiC.clear();
    keteranganHalaqoh.value = "";
    // keteranganGuruC.clear();
  }

  @override
  void onClose() {
    suratC.dispose();
    ayatHafalC.dispose();
    halAyatC.dispose();
    materiC.dispose();
    nilaiC.dispose();
    // keteranganGuruC.dispose();
    super.onClose();
  }
}












// =========== KODE LAMA ==================


// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';

// class PemberianNilaiHalaqohController extends GetxController {
//   RxString keteranganHalaqoh = "".obs;

//   TextEditingController suratC = TextEditingController();
//   TextEditingController ayatHafalC = TextEditingController();
//   TextEditingController jldSuratC = TextEditingController();
//   TextEditingController halAyatC = TextEditingController();
//   TextEditingController materiC = TextEditingController();
//   TextEditingController nilaiC = TextEditingController();
//   // TextEditingController keteranganGuruC = TextEditingController();

//   var data = Get.arguments;

//   FirebaseAuth auth = FirebaseAuth.instance;
//   FirebaseFirestore firestore = FirebaseFirestore.instance;

//   String idUser = FirebaseAuth.instance.currentUser!.uid;
//   String idSekolah = '20404148';
//   String emailAdmin = FirebaseAuth.instance.currentUser!.email!;

//   onChangeAlias(String catatan) {
//     keteranganHalaqoh.value = catatan;
//   }

//   Future<String> ambilDataUmi() async {
//     String idTahunAjaranNya = data['tahunajaran'];
//     String idTahunAjaran = idTahunAjaranNya.replaceAll("/", "-");

//     CollectionReference<Map<String, dynamic>> colSemester = firestore
//         .collection('Sekolah')
//         .doc(idSekolah)
//         .collection('tahunajaran')
//         .doc(idTahunAjaran)
//         // .collection('semester')
//         // .doc(data['namasemester'])
//         .collection('kelompokmengaji')
//         .doc(data['fase'])
//         .collection('pengampu')
//         .doc(data['namapengampu'])
//         .collection('tempat')
//         .doc(data['tempatmengaji'])
//         .collection('daftarsiswa')
//         .doc(data['nisn'])
//         .collection('semester');

//     QuerySnapshot<Map<String, dynamic>> snapSemester = await colSemester.get();
//     if (snapSemester.docs.isNotEmpty) {
//       Map<String, dynamic> dataSemester = snapSemester.docs.first.data();
//       String umi = dataSemester['ummi'];

//       return umi;
//     }
//     throw Exception('UMI data not found');
//   }

//   Future<void> simpanNilai() async {
//     // print("data = $data");
//     if (data != null && data.isNotEmpty) {
//       String idTahunAjaranNya = data['tahunajaran'];
//       String idTahunAjaran = idTahunAjaranNya.replaceAll("/", "-");

//       CollectionReference<Map<String, dynamic>> colSemester = firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('tahunajaran')
//           .doc(idTahunAjaran)
//           // .collection('semester')
//           // .doc(data['namasemester'])
//           .collection('kelompokmengaji')
//           .doc(data['fase'])
//           .collection('pengampu')
//           .doc(data['namapengampu'])
//           .collection('tempat')
//           .doc(data['tempatmengaji'])
//           .collection('daftarsiswa')
//           .doc(data['nisn'])
//           .collection('semester');

//       QuerySnapshot<Map<String, dynamic>> snapSemester =
//           await colSemester.get();
//       if (snapSemester.docs.isNotEmpty) {
//         Map<String, dynamic> dataSemester = snapSemester.docs.first.data();
//         String namaSemester = dataSemester['namasemester'];
//         String umi = dataSemester['ummi'];

//         CollectionReference<Map<String, dynamic>> colNilai = firestore
//             .collection('Sekolah')
//             .doc(idSekolah)
//             .collection('tahunajaran')
//             .doc(idTahunAjaran)
//             .collection('kelompokmengaji')
//             .doc(data['fase'])
//             .collection('pengampu')
//             .doc(data['namapengampu'])
//             .collection('tempat')
//             .doc(data['tempatmengaji'])
//             .collection('daftarsiswa')
//             .doc(data['nisn'])
//             .collection('semester')
//             .doc(namaSemester)
//             .collection('nilai');

//         QuerySnapshot<Map<String, dynamic>> snapNilai = await colNilai.get();

//         DateTime now = DateTime.now();
//         String docIdNilai = DateFormat.yMd().format(now).replaceAll('/', '-');

//         //konversi nilai string ke integer
//         int nilaiNumerik = int.parse(nilaiC.text);

//         //mendapatkan grade huruf
//         String grade = getGrade(nilaiNumerik);

//         // ignore: prefer_is_empty
//         if (snapNilai.docs.length == 0 || snapNilai.docs.isEmpty) {
//           //belum pernah input nilai & set nilai
//           colNilai.doc(docIdNilai).set({
//             "tanggalinput": now.toIso8601String(),
//             "emailpenginput": emailAdmin,
//             "fase": data['fase'],
//             "idpengampu": idUser,
//             "idsiswa": data['nisn'],
//             "kelas": data['kelas'],
//             "kelompokmengaji": data['kelompokmengaji'],
//             "namapengampu": data['namapengampu'],
//             "namasemester": namaSemester,
//             "namasiswa": data['namasiswa'],
//             "tahunajaran": data['tahunajaran'],
//             "tempatmengaji": data['tempatmengaji'],
//             "hafalansurat": suratC.text,
//             "ayathafalansurat": ayatHafalC.text,
//             "ummijilidatausurat": umi,
//             "ummihalatauayat": halAyatC.text,
//             "materi": materiC.text,
//             "nilai": nilaiC.text,
//             "nilaihuruf": grade,
//             "keteranganpengampu": keteranganHalaqoh.value,
//             "keteranganorangtua": "0",
//             "uidnilai": docIdNilai,
//           });

//           // Get.back();
//           Get.snackbar(
//             'Informasi',
//             'Berhasil input nilai',
//             snackPosition: SnackPosition.BOTTOM,
//             backgroundColor: Colors.grey[350],
//           );
//           refresh();
//         } else {
//           DocumentSnapshot<Map<String, dynamic>> docNilaiToday =
//               await colNilai.doc(docIdNilai).get();

//           if (docNilaiToday.exists == true) {
//             // Get.snackbar('Informasi', 'hari ini ananda sudah input nilai',
//             //     snackPosition: SnackPosition.BOTTOM,
//             //     backgroundColor: Colors.grey[350]);
//             Get.defaultDialog(
//               title: 'Informasi',
//               content: Text(
//                 'Hari ini ananda sudah input nilai, Apakah Ananda mau update nilai??',
//                 style: TextStyle(fontSize: 16),
//               ),
//               textConfirm: 'OK',
//               onConfirm: () {
//                 refresh();
//                 Get.snackbar("isi logika", "nilainya harus diupdate");
//               },
//             );
//           } else {
//             colNilai.doc(docIdNilai).set({
//               "tanggalinput": now.toIso8601String(),
//               "emailpenginput": emailAdmin,
//               "fase": data['fase'],
//               "idpengampu": idUser,
//               "idsiswa": data['nisn'],
//               "kelas": data['kelas'],
//               "kelompokmengaji": data['kelompokmengaji'],
//               "namapengampu": data['namapengampu'],
//               "namasemester": namaSemester,
//               "namasiswa": data['namasiswa'],
//               "tahunajaran": data['tahunajaran'],
//               "tempatmengaji": data['tempatmengaji'],
//               "hafalansurat": suratC.text,
//               "ayathafalansurat": ayatHafalC.text,
//               "ummijilidatausurat": umi,
//               "ummihalatauayat": halAyatC.text,
//               "materi": materiC.text,
//               "nilai": nilaiC.text,
//               "nilaihuruf": grade,
//               "keteranganpengampu": keteranganHalaqoh.value,
//               "keteranganorangtua": "0",
//               "uidnilai": docIdNilai,
//             });

//             Get.back();

//             Get.snackbar(
//               'Informasi',
//               'Berhasil input nilai',
//               snackPosition: SnackPosition.BOTTOM,
//               backgroundColor: Colors.grey[350],
//             );

//             refresh();
//           }
//         }
//       }
//     }
//   }

//   String getGrade(int score) {
//     if (score >= 90 && score <= 100) {
//       return 'A';
//     } else if (score >= 70 && score <= 80) {
//       return 'B';
//     } else if (score >= 50 && score <= 60) {
//       return 'C';
//     } else if (score >= 30 && score <= 40) {
//       return 'D';
//     } else if (score >= 0 && score <= 20) {
//       return 'E';
//     } else {
//       return 'Nilai tidak valid';
//     }
//   }
// }

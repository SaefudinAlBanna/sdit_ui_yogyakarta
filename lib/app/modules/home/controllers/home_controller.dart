import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'dart:async';

import '../pages/home.dart';
import '../pages/marketplace.dart';
import '../pages/profile.dart';

class HomeController extends GetxController {
  RxInt indexWidget = 0.obs;
  RxBool isLoading = false.obs;
  RxBool isLoadingInitialData = true.obs; // Untuk loading tahun ajaran & kelas
  RxString jamPelajaranRx = 'Memuat jam...'.obs;
  RxList<DocumentSnapshot<Map<String, dynamic>>> kelasAktifList =
      <DocumentSnapshot<Map<String, dynamic>>>[].obs;


  Timer? _timer;

  Rxn<String> selectedItem = Rxn<String>();

  TextEditingController kelasSiswaC = TextEditingController();
  TextEditingController tahunAjaranBaruC = TextEditingController();
  TextEditingController mapelC = TextEditingController();

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  String idUser = FirebaseAuth.instance.currentUser!.uid;
  String idSekolah = "20404148";
  String emailAdmin = FirebaseAuth.instance.currentUser!.email!;

  void changeIndex(int index) {
    indexWidget.value = index;
  }

  String? idTahunAjaran;

  // @override
  // void onInit() async {
  //   super.onInit();
  //   String tahunajaranya = await getTahunAjaranTerakhir();
  //   idTahunAjaran = tahunajaranya.replaceAll("/", "-");
  //   jamPelajaranRx.value = getJamPelajaranSaatIni();
  //   print('jamPelajaranRx.value (init): ${jamPelajaranRx.value}');
  //   update();

  //   _timer = Timer.periodic(Duration(minutes: 1), (timer) {
  //     jamPelajaranRx.value = getJamPelajaranSaatIni();
  //     print('jamPelajaranRx.value (timer): ${jamPelajaranRx.value}');
  //     update();
  //   });
  // }

  @override
  void onInit() async {
    super.onInit();
     _initializeController();
    isLoading.value = true; // Set loading state
    try {
      String tahunAjaranAktif = await getTahunAjaranTerakhir();
      idTahunAjaran = tahunAjaranAktif.replaceAll("/", "-");
      jamPelajaranRx.value = getJamPelajaranSaatIni();
      print('HomeController onInit: idTahunAjaran = $idTahunAjaran, jamPelajaranRx = ${jamPelajaranRx.value}');
      update(); // Untuk GetBuilder jika ada yang bergantung pada idTahunAjaran
    } catch (e) {
      print("Error initializing HomeController: $e");
      // Handle error, mungkin tampilkan pesan ke user
    } finally {
      isLoading.value = false;
    }

    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      final newJam = getJamPelajaranSaatIni();
      if (newJam != jamPelajaranRx.value) {
        jamPelajaranRx.value = newJam;
        print('HomeController Timer: jamPelajaranRx updated to ${jamPelajaranRx.value}');
        // Tidak perlu update() di sini jika UI menggunakan Obx untuk jamPelajaranRx
      }
    });
  }

  Future<void> _initializeController() async {
    isLoadingInitialData.value = true;
    if (auth.currentUser == null) {
      print("Error: Pengguna belum login.");
      // Mungkin redirect ke login atau tampilkan pesan error
      Get.snackbar("Error", "Sesi tidak valid, silakan login ulang.");
      isLoadingInitialData.value = false;
      jamPelajaranRx.value = "Error: Sesi tidak valid";
      // Consider calling signOut() or navigating to login
      return;
    }
    idUser = auth.currentUser!.uid;
    emailAdmin = auth.currentUser!.email!;

    try {
      String tahunAjaranAktif = await _getTahunAjaranTerakhir();
      idTahunAjaran = tahunAjaranAktif.replaceAll("/", "-");
      print('HomeController: idTahunAjaran diinisialisasi menjadi $idTahunAjaran');

      await _fetchKelasAktif(); // Ambil daftar kelas

      jamPelajaranRx.value = _getJamPelajaranSaatIni();
      _startTimer();
      update(); // Untuk GetBuilder yang mungkin bergantung pada _idTahunAjaran
    } catch (e) {
      print("Error initializing HomeController: $e");
      Get.snackbar("Kesalahan Inisialisasi", "Gagal memuat data awal: ${e.toString()}");
      jamPelajaranRx.value = "Error memuat data";
    } finally {
      isLoadingInitialData.value = false;
    }
  }

  void _startTimer() {
    _timer?.cancel(); // Cancel timer lama jika ada
    _timer = Timer.periodic(Duration(seconds: 30), (timer) { // Interval 30 detik untuk testing
      final newJam = _getJamPelajaranSaatIni();
      if (newJam != jamPelajaranRx.value) {
        jamPelajaranRx.value = newJam;
        print('HomeController Timer: jamPelajaranRx updated to ${jamPelajaranRx.value}');
      }
    });
  }

  Future<String> _getTahunAjaranTerakhir() async {
    QuerySnapshot<Map<String, dynamic>> snapshotTahunAjaran = await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        // Anda mungkin perlu order by field tertentu jika ingin yang "terakhir" secara kronologis
        // .orderBy('tanggalDibuat', descending: true) // Contoh jika ada field 'tanggalDibuat'
        .get();

    if (snapshotTahunAjaran.docs.isEmpty) {
      throw Exception("Tidak ada data tahun ajaran ditemukan.");
    }
    // Mengambil yang terakhir berdasarkan ID dokumen jika ID nya bisa diurutkan (misal "2023-2024", "2024-2025")
    // Atau jika field 'namatahunajaran' bisa diurutkan
    List<String> namaTahunAjaranList = snapshotTahunAjaran.docs
        .map((doc) => doc.data()['namatahunajaran'] as String)
        .toList();
    namaTahunAjaranList.sort(); // Sorts alphabetically/numerically
    if (namaTahunAjaranList.isEmpty) throw Exception("List nama tahun ajaran kosong setelah map.");
    return namaTahunAjaranList.last;
  }

  Future<void> _fetchKelasAktif() async {
    if (idTahunAjaran == null) {
      print("Tidak bisa fetch kelas aktif, idTahunAjaran null.");
      kelasAktifList.clear();
      return;
    }
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran!)
          .collection('kelasaktif')
          .get();
      kelasAktifList.assignAll(snapshot.docs);
      print("Kelas aktif berhasil diambil: ${kelasAktifList.length} kelas");
    } catch (e) {
      print("Error fetching kelas aktif: $e");
      Get.snackbar("Error", "Gagal memuat daftar kelas: ${e.toString()}");
      kelasAktifList.clear();
    }
  }

  String _getJamPelajaranSaatIni() {
    DateTime now = DateTime.now();
    int currentMinutes = now.hour * 60 + now.minute;

    // List ID dokumen jam pelajaran yang ada di Firestore Anda
    // Format ID ini HARUS PERSIS seperti di subkoleksi 'jurnalkelas'
    // Contoh: '07-00-07.05', '07.05-07.30'
    List<Map<String, String>> jadwalPelajaran = [
      {'id': '07-00-07.05', 'start': '07.00', 'end': '07.05'},
      {'id': '07.05-07.30', 'start': '07.05', 'end': '07.30'},
      {'id': '21.30-21.55', 'start': '21.30', 'end': '21.55'},
      {'id': '21.55-22.08', 'start': '21.55', 'end': '22.08'},
      {'id': '22.08-22.10', 'start': '22.08', 'end': '22.10'},
      {'id': '22.10-22.20', 'start': '22.10', 'end': '22.20'},
      // Tambahkan semua slot jam Anda di sini
    ];

    for (var jadwal in jadwalPelajaran) {
      try {
        int startMinutes = _parseTimeToMinutes(jadwal['start']!);
        int endMinutes = _parseTimeToMinutes(jadwal['end']!);

        if (currentMinutes >= startMinutes && currentMinutes < endMinutes) {
          return jadwal['id']!;
        }
      } catch (e) {
        print("Error parsing jadwal ${jadwal['id']}: $e. Pastikan format start/end HH.MM");
        continue;
      }
    }
    return 'Tidak ada jam pelajaran';
  }

  int _parseTimeToMinutes(String hhmm) { // Format HH.MM
    List<String> parts = hhmm.split('.');
    if (parts.length != 2) throw FormatException("Format waktu tidak valid: $hhmm. Harusnya HH.MM");
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getStreamJurnalDetail(
    String idKelas,
    String jamPelajaranDocId,
  ) {
    if (idTahunAjaran == null || jamPelajaranDocId == 'Tidak ada jam pelajaran' || jamPelajaranDocId.isEmpty || jamPelajaranDocId == 'Memuat jam...') {
      // Return an empty stream if no valid jamPelajaranDocId
      // kode sebelumnya dari ai
      //  return Stream.value(FirestoreQueryBuilder.emptyDocumentSnapshot()); -> ERROR
      return const Stream.empty();
    }
    DateTime now = DateTime.now();
    String docIdTanggalJurnal = DateFormat('d-M-yyyy').format(now); // Sesuai path Anda: "6-2-2025"

    return firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran!)
        .collection('kelasaktif')
        .doc(idKelas)
        .collection('tanggaljurnal')
        .doc(docIdTanggalJurnal)
        .collection('jurnalkelas')
        .doc(jamPelajaranDocId) // Ini adalah ID dokumen jam pelajaran
        .snapshots();
  }

// Helper class untuk stream kosong agar tidak error saat snapshot null
  // dihapus system

  // Helper class untuk stream kosong agar tidak error saat snapshot null

// Move these classes to the top-level (outside HomeController)
// class FirestoreQueryBuilder {
//   static DocumentSnapshot<Map<String, dynamic>> emptyDocumentSnapshot() {
//     return _EmptyDocumentSnapshot();
//   }
// }

// class _EmptyDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
//   @override
//   Map<String, dynamic>? data() => null;
//   @override
//   bool get exists => false;
//   @override
//   String get id => ''; // Atau ID yang menandakan kosong
//   @override
//   SnapshotMetadata get metadata => throw UnimplementedError("Metadata not available for empty snapshot");
//   @override
//   DocumentReference<Map<String, dynamic>> get reference => throw UnimplementedError("Reference not available for empty snapshot");
//   @override
//   dynamic get(Object field) => null;
//   @override
//   dynamic operator [](Object field) => null;
// }
      
  void clearForm() {
    kelasSiswaC.clear();
    tahunAjaranBaruC.clear();
    selectedItem.value = null; // Reset dropdown
    // Tambahkan pembersihan untuk widget lain di sini jika ada
    // print("Form dibersihkan!");
  }

  @override
  void onClose() {
    _timer?.cancel();
    kelasSiswaC.dispose();
    tahunAjaranBaruC.dispose();
    super.onClose();
  }

  final List<Widget> myWidgets = [HomePage(), MarketplacePage(), ProfilePage()];

  void signOut() async {
    isLoading.value = true;
    await auth.signOut();
    isLoading.value = false;
    Get.offAllNamed('/login');
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userStreamBaru() async* {
    yield* firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(idUser)
        .snapshots();
  }

  

  Future<void> simpanTahunAjaran() async {
    String uid = auth.currentUser!.uid;
    String emailPenginput = auth.currentUser!.email!;

    DocumentReference<Map<String, dynamic>> ambilDataPenginput = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(uid);

    DocumentSnapshot<Map<String, dynamic>> snapDataPenginput =
        await ambilDataPenginput.get();

    CollectionReference<Map<String, dynamic>> colTahunAjaran = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran');
    QuerySnapshot<Map<String, dynamic>> snapshotTahunAjaran =
        await colTahunAjaran.get();
    List<Map<String, dynamic>> listTahunAjaran =
        snapshotTahunAjaran.docs.map((e) => e.data()).toList();

    //ambil namatahunajaranya
    listTahunAjaran.map((e) => e['namatahunajaran']).toList();

    // buat documen id buat tahun ajaran
    String idTahunAjaran = tahunAjaranBaruC.text.replaceAll("/", "-");

    if (listTahunAjaran.elementAt(0)['namatahunajaran'] !=
        tahunAjaranBaruC.text) {
      if (!listTahunAjaran.any(
        (element) => element['namatahunajaran'] == tahunAjaranBaruC.text,
      )) {
        //belum input tahun ajaran yang baru, maka bikin tahun ajaran baru
        colTahunAjaran
            .doc(idTahunAjaran)
            .set({
              'namatahunajaran': tahunAjaranBaruC.text,
              'idpenginput': uid,
              'emailpenginput': emailPenginput,
              'namapenginput': snapDataPenginput.data()?['nama'],
              'tanggalinput': DateTime.now().toString(),
              'idtahunajaran': idTahunAjaran,
            })
            .then(
              (value) => {
                Get.snackbar('Berhasil', 'Tahun ajaran sudah berhasil dibuat'),
                tahunAjaranBaruC.text = "",
              },
            );
      } else {
        Get.snackbar('Gagal', 'Tahun ajaran sudah ada');
      }
      // Get.back();
    }
    // Get.back();
  }

  Future<String?> getDataKelasWali() async {
  String tahunajaranya = await getTahunAjaranTerakhir();
  String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

  QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
      .collection('Sekolah')
      .doc(idSekolah)
      .collection('tahunajaran')
      .doc(idTahunAjaran)
      .collection('kelastahunajaran')
      .where('idwalikelas', isEqualTo: idUser)
      .get();

  if (snapshot.docs.isNotEmpty) {
    return snapshot.docs.first.id;
  } else {
    // print('Tidak ditemukan kelas untuk walikelas dengan id: $idUser');
    // Get.snackbar("Informasi", "Tidak ada catatan dalam kelas anda");
    return null;
  }
}

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

  Future<List<String>> getDataFase() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    // String idSemester = 'Semester I';  // nanti ini diambil dari database

    List<String> faseList = [];

    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelompokmengaji')
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            faseList.add(docSnapshot.id);
          }
        });
    return faseList;
  }

  Future<List<String>> getDataKelasYangDiajar() async {
    String tahunajaranya =
        await getTahunAjaranTerakhir(); // ambil dari tahun ajaran di collection pegawai
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    List<String> kelasList = [];
    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(idUser)
        .collection('tahunajaran')
        .doc(idTahunAjaran) // tahun ajaran yang d kelas pegawai
        .collection('kelasnya')
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            kelasList.add(docSnapshot.id);
          }
        });
    return kelasList;
  }

  Future<List<String>> getDataKelas() async {

    List<String> kelasList = [];
    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('kelas')
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            kelasList.add(docSnapshot.id);
          }
        });
    return kelasList;
  }


  Future<List<String>> getDataKelasMapel() async {
    String tahunajaranya =
        await getTahunAjaranTerakhir(); // ambil dari tahun ajaran di collection pegawai
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    List<String> kelasList = [];
    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelasaktif')
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            kelasList.add(docSnapshot.id);
          }
        });
    return kelasList;
  }

  Future<List<String>> getDataMapel(String kelas) async {
    String tahunajaranya =
        await getTahunAjaranTerakhir(); // ambil dari tahun ajaran di collection pegawai
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    List<String> mapelList = [];
    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(idUser)
        .collection('tahunajaran')
        .doc(idTahunAjaran) // tahun ajaran yang d kelas pegawai
        .collection('kelasnya')
        .doc(kelas)
        .collection('matapelajaran')
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            mapelList.add(docSnapshot.id);
          }
        });
    return mapelList;
  }

  Future<List<String>> getDataKelompok() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    // String idSemester = 'Semester I';

    List<String> kelasList = [];
    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(idUser)
        .collection('tahunajarankelompok')
        .doc(idTahunAjaran)
        // .collection('semester')
        // .doc(idSemester)
        .collection('kelompokmengaji')
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            kelasList.add(docSnapshot.id);
          }
        });
    // print('ini kelasList : $kelasList');
    return kelasList;
    // }
    // return [];
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getProfileBaru() async* {
    yield* firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(idUser)
        .snapshots();
  }



  Stream<QuerySnapshot<Map<String, dynamic>>> getDataInfo() async* {
    // ignore: unnecessary_null_comparison
    // if (idTahunAjaran == null) return const Stream.empty();

    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    yield* firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('informasisekolah')
        .orderBy('tanggalinput', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getDataJurnal() async* {
    yield* firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getDataJurnalKelas() {
    // ignore: unnecessary_null_comparison
    if (idTahunAjaran == null) return const Stream.empty();

    //   DateTime now = DateTime.now();
    //   String docIdJurnal = DateFormat.yMd().format(now).replaceAll('/', '-');

    return firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelasaktif')
        .snapshots();
  }

  // String getJamPelajaranSaatIni() {
  //   // DateTime now = DateTime.now();
  //   // String currentTime = DateFormat.Hm().format(now);
  //   DateTime now = DateTime.now();
  //   String currentTime = DateFormat.Hm().format(now).replaceAll(':', '.');
  //   print('currentTime: $currentTime');
  //   List<String> jamPelajaran = [
      
      
  //     '08.05-08.06',
  //   '08.06-08.09',
  //   '08.09-08.12',
  //   ];
  //   for (String jam in jamPelajaran) {
  //     List<String> range = jam.split('-');
  //     String startTime = range[0];
  //     String endTime = range[1];
  //     print('Cek: $currentTime >= $startTime && $currentTime < $endTime');
  //     if (currentTime.compareTo(startTime) >= 0 &&
  //         currentTime.compareTo(endTime) < 0) {
  //       print('MATCH: $jam');
  //       return jam;
  //     }
  //   }
  //   print('Tidak ada jam pelajaran');
  //   return 'Tidak ada jam pelajaran';
  // }

  String getJamPelajaranSaatIni() {
  DateTime now = DateTime.now();
  int currentMinutes = now.hour * 60 + now.minute;
  print('currentMinutes: $currentMinutes');
  List<String> jamPelajaran = [
    '07-00-07.05',
    '07.05-07.30',
    '08.00-08.45',

  ];
  for (String jam in jamPelajaran) {
    List<String> range = jam.split('-');
    int startMinutes = _parseToMinutes(range[0]);
    int endMinutes = _parseToMinutes(range[1]);
    print('Cek: $currentMinutes >= $startMinutes && $currentMinutes < $endMinutes');
    if (currentMinutes >= startMinutes && currentMinutes < endMinutes) {
      print('MATCH: $jam');
      return jam;
    }
  }
  print('Tidak ada jam pelajaran');
  return 'Tidak ada jam pelajaran';
}

int _parseToMinutes(String hhmm) {
  List<String> parts = hhmm.split('.');
  int hour = int.parse(parts[0]);
  int minute = int.parse(parts[1]);
  return hour * 60 + minute;
}

  void test() {
    // print("jamPelajaranRx.value = ${jamPelajaranRx.value}, getJamPelajaranSaatIni() = ${getJamPelajaranSaatIni()}");
    jamPelajaranRx.value = getJamPelajaranSaatIni();
    print('jamPelajaranRx.value (init): ${jamPelajaranRx.value}');
  }

  void tampilkanjurnal(String docId, String jamPelajaran) {
    getDataJurnalPerKelas(docId, jamPelajaran);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getDataJurnalPerKelas(
    String docId,
    String jamPelajaran,
  ) {
    // if (idTahunAjaran == null) return const Stream.empty();
    DateTime now = DateTime.now();
    String docIdJurnal = DateFormat.yMd().format(now).replaceAll('/', '-');

    // jamPelajaranRx.value = getJamPelajaranSaatIni();

    return firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelasaktif')
        .doc(docId)
        .collection('tanggaljurnal') // <-- ganti sesuai struktur Firestore
        .doc(docIdJurnal)
        .collection('jurnalkelas') // <-- ganti sesuai struktur Firestore
        // .where('jampelajaran', isEqualTo: jamPelajaran)
        // .where('jampelajaran', isEqualTo: getJamPelajaranSaatIni())
        .where('jampelajaran', isEqualTo: jamPelajaranRx.value)
        .snapshots();
  }
}

//**
//1. Menggunakan Tipe Data Numerik untuk Perbandingan
// Pendekatan ini lebih robust karena membandingkan angka lebih mudah dan akurat daripada membandingkan string waktu.
//Anda bisa mengubah semua waktu menjadi menit total dari tengah malam atau menggunakan objek DateTime secara langsung.
// Contoh Implementasi: */

void tampilkanSesuaiWaktu() {
  DateTime now = DateTime.now();
  int currentHour = now.hour;
  int currentMinute = now.minute;

  // Konversi waktu sekarang ke menit total dari tengah malam
  int currentTimeInMinutes = currentHour * 60 + currentMinute;

  // Definisikan rentang waktu dalam menit total
  // 01.00 - 01.30
  int startTime1 = 1 * 60 + 0;
  int endTime1 = 1 * 60 + 30;

  // 01.31 - 02.00
  int startTime2 = 1 * 60 + 31;
  int endTime2 = 2 * 60 + 0;

  // 02.01 - 02.30
  int startTime3 = 2 * 60 + 1;
  int endTime3 = 2 * 60 + 30;

  String isidataWaktu1 = 'pertama';
  String isidataWaktu2 = 'kedua';
  String isidataWaktu3 = 'ketiga';

  String tampilanYangSesuai =
      'Tidak ada data waktu yang cocok.'; // Default value

  if (currentTimeInMinutes >= startTime1 && currentTimeInMinutes <= endTime1) {
    tampilanYangSesuai = isidataWaktu1;
  } else if (currentTimeInMinutes >= startTime2 &&
      currentTimeInMinutes <= endTime2) {
    tampilanYangSesuai = isidataWaktu2;
  } else if (currentTimeInMinutes >= startTime3 &&
      currentTimeInMinutes <= endTime3) {
    tampilanYangSesuai = isidataWaktu3;
  }

  print('Waktu sekarang: $currentHour:$currentMinute');
  print('Tampilan yang sesuai: $tampilanYangSesuai');

  // Di sini Anda bisa memperbarui UI berdasarkan nilai tampilanYangSesuai
  // Contoh: setState(() { _dataYangDitampilkan = tampilanYangSesuai; });
}

//*** 2. Menggunakan Objek DateTime dan isAfter/isBefore
//Ini adalah cara yang lebih modern dan direkomendasikan
//karena DateTime dirancang untuk perbandingan waktu.
//Anda bisa membuat objek DateTime untuk waktu mulai dan
//akhir setiap rentang.
// */
void tampilkanSesuaiWaktuDenganDateTime() {
  DateTime now = DateTime.now();

  // Penting: Pastikan Anda hanya membandingkan jam dan menit saja
  // atau pastikan rentang waktu yang Anda definisikan adalah untuk hari yang sama.
  // Untuk perbandingan waktu harian saja (tanpa mempertimbangkan tanggal):
  DateTime timeOnly(int hour, int minute) {
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  // Definisikan rentang waktu menggunakan objek DateTime
  DateTime start1 = timeOnly(1, 0); // 01.00
  DateTime end1 = timeOnly(1, 30); // 01.30

  DateTime start2 = timeOnly(1, 31); // 01.31
  DateTime end2 = timeOnly(2, 0); // 02.00

  DateTime start3 = timeOnly(2, 1); // 02.01
  DateTime end3 = timeOnly(4, 30); // 02.30

  String isidataWaktu1 = 'pertama';
  String isidataWaktu2 = 'kedua';
  String isidataWaktu3 = 'ketiga';

  String tampilanYangSesuai = 'Tidak ada data waktu yang cocok.';

  // Perbandingan menggunakan isAfter dan isBefore
  if ((now.isAfter(start1) || now.isAtSameMomentAs(start1)) &&
      (now.isBefore(end1) || now.isAtSameMomentAs(end1))) {
    tampilanYangSesuai = isidataWaktu1;
  } else if ((now.isAfter(start2) || now.isAtSameMomentAs(start2)) &&
      (now.isBefore(end2) || now.isAtSameMomentAs(end2))) {
    tampilanYangSesuai = isidataWaktu2;
  } else if ((now.isAfter(start3) || now.isAtSameMomentAs(start3)) &&
      (now.isBefore(end3) || now.isAtSameMomentAs(end3))) {
    tampilanYangSesuai = isidataWaktu3;
  }

  print('Waktu sekarang: ${now.hour}:${now.minute}');
  print('Tampilan yang sesuai: $tampilanYangSesuai');
}

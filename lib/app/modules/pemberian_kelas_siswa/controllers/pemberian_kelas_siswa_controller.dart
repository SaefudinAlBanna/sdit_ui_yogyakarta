import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

// Add this import if MataPelajaranConverter is defined elsewhere
// import 'path_to_mata_pelajaran_converter.dart';

// Define MataPelajaranConverter if not already defined
class MataPelajaranConverter {
  MataPelajaranConverter();

  // Example implementation, adjust as needed for your model
  Map<String, dynamic> fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    _,
  ) {
    return snapshot.data()!;
  }

  Map<String, dynamic> toFirestore(Map<String, dynamic> mataPelajaran, _) {
    return mataPelajaran;
  }
}

class PemberianKelasSiswaController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isLoadingTambahKelas = false.obs;
  var argumentKelas = Get.arguments;

  TextEditingController waliKelasSiswaC = TextEditingController();
  TextEditingController idPegawaiC = TextEditingController();
  TextEditingController namaSiswaC = TextEditingController();
  TextEditingController nisnSiswaC = TextEditingController();
  TextEditingController namaTahunAjaranTerakhirC = TextEditingController();

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  String idUser = FirebaseAuth.instance.currentUser!.uid;
  String idSekolah = '20404148';
  String emailAdmin = FirebaseAuth.instance.currentUser!.email!;

  late Stream<QuerySnapshot<Map<String, dynamic>>> tampilkanSiswa;

  @override
  void onInit() {
    super.onInit();

    tampilkanSiswa =
        FirebaseFirestore.instance
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('siswa')
            .where('status', isNotEqualTo: 'aktif')
            .snapshots();
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

  Future<List<String>> getDataWaliKelasBaru() async {
    List<String> waliKelasBaruList = [];

    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    QuerySnapshot<Map<String, dynamic>> snapKelas =
        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('tahunajaran')
            .doc(idTahunAjaran)
            .collection('kelastahunajaran')
            .get();

    String namaWalikelas =
        snapKelas.docs.isNotEmpty
            ? snapKelas.docs.first.data()['walikelas']
            : '';

    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .where('alias', isNotEqualTo: namaWalikelas)
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs.where(
            (doc) => doc['role'] == 'Guru Kelas',
          )) {
            waliKelasBaruList.add(docSnapshot.data()['alias']);
            // waliKelasBaruList.add(docSnapshot.data()['nip']);
          }
        });
    return waliKelasBaruList;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getDataWali() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    CollectionReference<Map<String, dynamic>> colKelas = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelastahunajaran');

    try {
      return await colKelas.get();
      // Example return statement
    } catch (e) {
      // print('Error occurred: $e');
      throw Exception('Failed to fetch data: $e');
    }
  }

  Future<void> tambahDaftarKelasGuruAjar() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    String kelasNya = argumentKelas.substring(0, 1);
    String faseNya =
        (kelasNya == '1' || kelasNya == '2')
            ? "Fase A"
            : (kelasNya == '3' || kelasNya == '4')
            ? "Fase B"
            : "Fase C";

    //ambil data guru terpilih
    QuerySnapshot<Map<String, dynamic>> querySnapshotGuru =
        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('pegawai')
            .where('alias', isEqualTo: waliKelasSiswaC.text)
            .get();
    if (querySnapshotGuru.docs.isNotEmpty) {
      Map<String, dynamic> dataGuru = querySnapshotGuru.docs.first.data();
      String uidGuru = dataGuru['uid'];

      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('pegawai')
          .doc(uidGuru)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .set({
            'tahunajaran': tahunajaranya,
            'idpenginput': idUser,
            'tanggalinput': DateTime.now().toIso8601String(),
          });

      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('pegawai')
          .doc(uidGuru)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelasnya')
          .doc(argumentKelas)
          .set({
            'namakelas': argumentKelas,
            'fase': faseNya,
            'tahunajaran': tahunajaranya,
            'emailpenginput': emailAdmin,
            'idpenginput': idUser,
            'tanggalinput': DateTime.now().toIso8601String(),
          });
    }
  }

  Future<void> kelasUntukSiswaNext(String nisnSiswa, String namaSiswa) async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    String kelasNya = argumentKelas.substring(0, 1);
    String faseNya =
        (kelasNya == '1' || kelasNya == '2')
            ? "Fase A"
            : (kelasNya == '3' || kelasNya == '4')
            ? "Fase B"
            : "Fase C";

    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('siswa')
        .doc(nisnSiswa)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .set({
          'fase': faseNya,
          'nisn': nisnSiswa,
          'tahunajaran': tahunajaranya,
          'idpenginput': idUser,
          'tanggalinput': DateTime.now().toIso8601String(),
        });

    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('siswa')
        .doc(nisnSiswa)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelasnya')
        .doc(argumentKelas)
        .set({
          'namasiswa': namaSiswa,
          'nisn': nisnSiswa,
          'namakelas': argumentKelas,
          'fase': faseNya,
          'tahunajaran': tahunajaranya,
          'emailpenginput': emailAdmin,
          'idpenginput': idUser,
          'tanggalinput': DateTime.now().toIso8601String(),
        });
    // }
  }

  Future<void> ubahStatusSiswaNext(String nisnSiSwa) async {
    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('siswa')
        .doc(nisnSiSwa)
        .update({'status': 'aktif'});
  }

  Future<void> buatIsiKelasTahunAjaran() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    String kelasNya = argumentKelas.substring(0, 1);
    String faseNya =
        (kelasNya == '1' || kelasNya == '2')
            ? "Fase A"
            : (kelasNya == '3' || kelasNya == '4')
            ? "Fase B"
            : "Fase C";

    QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('pegawai')
            .where('alias', isEqualTo: waliKelasSiswaC.text)
            .get();

    // Check if the query returned any documents
    if (querySnapshot.docs.isEmpty) {
      Get.snackbar(
        'Error',
        'Wali kelas tidak ditemukan. Pastikan alias wali kelas benar.',
      );
      return; // Exit the function if no documents are found
    }

    String uidWaliKelasnya = querySnapshot.docs.first.data()['uid'];

    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelastahunajaran')
        .doc(argumentKelas)
        .set({
          'namakelas': argumentKelas,
          'fase': faseNya,
          'walikelas': waliKelasSiswaC.text,
          'idwalikelas': uidWaliKelasnya,
          'tahunajaran': tahunajaranya,
          'emailpenginput': emailAdmin,
          'idpenginput': idUser,
          'tanggalinput': DateTime.now().toIso8601String(),
        });
  }

  // Future<void> buatIsiSemester1(String namaSiswa, String nisnSiswa) async {
  //   String tahunajaranya = await getTahunAjaranTerakhir();
  //   String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
  //   String kelasNya = argumentKelas.substring(0, 1);
  //   String faseNya =
  //       (kelasNya == '1' || kelasNya == '2')
  //           ? "Fase A"
  //           : (kelasNya == '3' || kelasNya == '4')
  //           ? "Fase B"
  //           : "Fase C";

  //   QuerySnapshot<Map<String, dynamic>> querySnapshot =
  //       await firestore
  //           .collection('Sekolah')
  //           .doc(idSekolah)
  //           .collection('pegawai')
  //           .where('alias', isEqualTo: waliKelasSiswaC.text)
  //           .get();

  //   // Check if the query returned any documents
  //   if (querySnapshot.docs.isEmpty) {
  //     Get.snackbar(
  //       'Error',
  //       'Wali kelas tidak ditemukan. Pastikan alias wali kelas benar.',
  //     );
  //     return; // Exit the function if no documents are found
  //   }

  //   String uidWaliKelasnya = querySnapshot.docs.first.data()['uid'];

  //   await firestore
  //       .collection('Sekolah')
  //       .doc(idSekolah)
  //       .collection('tahunajaran')
  //       .doc(idTahunAjaran)
  //       .collection('kelastahunajaran')
  //       .doc(argumentKelas)
  //       .collection('daftarsiswa')
  //       .doc(nisnSiswa)
  //       .collection('semester')
  //       .doc('Semester I')
  //       .set({
  //         'namasemester': 'Semester I',
  //         'namasiswa': namaSiswa,
  //         'nisnsiswa': nisnSiswa,
  //         'namakelas': argumentKelas,
  //         'fase': faseNya,
  //         'walikelas': waliKelasSiswaC.text,
  //         'idwalikelas': uidWaliKelasnya,
  //         'tahunajaran': tahunajaranya,
  //         'emailpenginput': emailAdmin,
  //         'idpenginput': idUser,
  //         'tanggalinput': DateTime.now().toIso8601String(),
  //       });
  // }

  Future<void> simpanKelasBaru(String namaSiswa, String nisnSiswa) async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    String kelasNya = argumentKelas.substring(0, 1);
    String faseNya =
        (kelasNya == '1' || kelasNya == '2')
            ? "Fase A"
            : (kelasNya == '3' || kelasNya == '4')
            ? "Fase B"
            : "Fase C";

    CollectionReference<Map<String, dynamic>> colKelas = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelastahunajaran');
    DocumentSnapshot<Map<String, dynamic>> docIdKelas =
        await colKelas.doc(argumentKelas).get();

    // Helper function untuk membuat data map yang konsisten
    Map<String, dynamic> _createDataMap({
      required String namaKelas,
      required String fase,
      required String tahunAjaran,
      required String walikelas,
      required String idwalikelas,
      String? namaSiswa,
      String? nisn,
      String? namamatapelajaran,
    }) {
      return {
        'namakelas': namaKelas,
        'fase': fase,
        'tahunajaran': tahunAjaran,
        'walikelas': walikelas,
        'idwalikelas': idwalikelas,
        'emailpenginput': emailAdmin,
        'idpenginput': idUser,
        'tanggalinput': DateTime.now().toIso8601String(),
        if (namaSiswa != null) 'namasiswa': namaSiswa,
        if (nisn != null) 'nisn': nisn,
        if (namamatapelajaran != null) 'namamatapelajaran': namamatapelajaran,
      };
    }

    WriteBatch batch = firestore.batch();
    // Inisialisasi batch
    try {
      if (docIdKelas.exists) {
        // Ambil data wali kelas dan ID wali kelas dari dokumen kelas
        String walikelas = docIdKelas.data()!['walikelas'];
        String idwalikelas = docIdKelas.data()!['idwalikelas'];
        // Data untuk kelas
        Map<String, dynamic> dataKelas = _createDataMap(
          namaKelas: argumentKelas,
          fase: faseNya,
          tahunAjaran: tahunajaranya,
          walikelas: walikelas,
          idwalikelas: idwalikelas,
        );
        //Data untuk semester
        Map<String, dynamic> dataSemester = _createDataMap(
          namaKelas: argumentKelas,
          fase: faseNya,
          tahunAjaran: tahunajaranya,
          walikelas: walikelas,
          idwalikelas: idwalikelas,
        );
        //Data untuk daftar siswa
        Map<String, dynamic> dataDaftarSiswa = {
          ..._createDataMap(
            namaKelas: argumentKelas,
            fase: faseNya,
            tahunAjaran: tahunajaranya,
            walikelas: walikelas,
            idwalikelas: idwalikelas,
            namaSiswa: namaSiswa,
            nisn: nisnSiswa,
          ),
          'status': 'aktif',
          'idsiswa': nisnSiswa,
          'statuskelompok': 'baru',
          'namasemester': 'Semester I',
        };
        // Referensi dokumen yang akan diubah
        DocumentReference kelasDocRef = colKelas.doc(argumentKelas);
        DocumentReference semesterDocRef = kelasDocRef
            .collection('semester')
            .doc('Semester I');
        DocumentReference daftarSiswaDocRef = semesterDocRef
            .collection('daftarsiswa')
            .doc(nisnSiswa);
        // Tambahkan operasi ke batch
        batch.set(kelasDocRef, dataKelas);
        batch.set(semesterDocRef, dataSemester);
        batch.set(daftarSiswaDocRef, dataDaftarSiswa);
        // Daftar mata pelajaran
        List<String> mataPelajaran = [
          "Pendidikan Pancasila dan Kewarganegaraan (PPKn)",
          "Ilmu Pengetahuan Alam dan Sosial (IPAS)",
          "Bahasa Indonesia",
          "Pendidikan Agama Islam dan Budi Pekerti",
          "Matematika",
          "Pendidikan Jasmani, Olahraga, dan Kesehatan (PJOK)",
          "Bahasa Inggris",
        ];
        // Tambahkan mata pelajaran ke batch
        for (String pelajaran in mataPelajaran) {
          Map<String, dynamic> dataMataPelajaran = _createDataMap(
            namaKelas: argumentKelas,
            fase: faseNya,
            tahunAjaran: tahunajaranya,
            walikelas: walikelas,
            idwalikelas: idwalikelas,
            namamatapelajaran: pelajaran,
          );
          batch.set(
            daftarSiswaDocRef.collection('matapelajaran').doc(pelajaran),
            dataMataPelajaran,
          );
        }
        // Commit batch
        await batch.commit();
        // Panggil fungsi lain
        await tambahDaftarKelasGuruAjar();
        await kelasUntukSiswaNext(nisnSiswa, namaSiswa);
        await ubahStatusSiswaNext(nisnSiswa);
      } else {
        // Dokumen kelas tidak ditemukan -> buat data kelas baru
        QuerySnapshot<Map<String, dynamic>> querySnapshot =
            await firestore
                .collection('Sekolah')
                .doc(idSekolah)
                .collection('pegawai')
                .where('alias', isEqualTo: waliKelasSiswaC.text)
                .get();
        if (querySnapshot.docs.isEmpty) {
          Get.snackbar('Error', 'Wali kelas tidak ditemukan.');
          return;
        }
        String uidWaliKelasnya = querySnapshot.docs.first.data()!['uid'];
        // Cek apakah wali kelas sudah ada di kelas lain
        QuerySnapshot<Map<String, dynamic>> snapKelas = await colKelas.get();
        List<String> waliKelasBaruList =
            snapKelas.docs
                .where((doc) => doc.data()!['walikelas'] != null)
                .map((doc) => doc.data()!['walikelas'] as String)
                .toList();
        if (waliKelasBaruList.contains(waliKelasSiswaC.text)) {
          Get.snackbar(
            'Error',
            'Wali kelas sudah ada di kelas lain, silakan pilih yang lain.',
          );
          return;
        }
        // Jika semua validasi lolos, buat data kelas baru
        Map<String, dynamic> dataKelasBaru = _createDataMap(
          namaKelas: argumentKelas,
          fase: faseNya,
          tahunAjaran: tahunajaranya,
          walikelas: waliKelasSiswaC.text,
          idwalikelas: uidWaliKelasnya,
        );
        //Data untuk semester
        Map<String, dynamic> dataSemesterBaru = _createDataMap(
          namaKelas: argumentKelas,
          fase: faseNya,
          tahunAjaran: tahunajaranya,
          walikelas: waliKelasSiswaC.text,
          idwalikelas: uidWaliKelasnya,
        );
        //Data untuk daftar siswa
        Map<String, dynamic> dataDaftarSiswaBaru = {
          ..._createDataMap(
            namaKelas: argumentKelas,
            fase: faseNya,
            tahunAjaran: tahunajaranya,
            walikelas: waliKelasSiswaC.text,
            idwalikelas: uidWaliKelasnya,
            namaSiswa: namaSiswa,
            nisn: nisnSiswa,
          ),
          'status': 'aktif',
          'idsiswa': nisnSiswa,
          'statuskelompok': 'baru',
          'namasemester': 'Semester I',
        };
        // Referensi dokumen yang akan diubah
        DocumentReference kelasDocRefBaru = colKelas.doc(argumentKelas);
        DocumentReference semesterDocRefBaru = kelasDocRefBaru
            .collection('semester')
            .doc('Semester I');
        DocumentReference daftarSiswaDocRefBaru = semesterDocRefBaru
            .collection('daftarsiswa')
            .doc(nisnSiswa);
        // Tambahkan operasi ke batch
        batch.set(kelasDocRefBaru, dataKelasBaru);
        batch.set(semesterDocRefBaru, dataSemesterBaru);
        batch.set(daftarSiswaDocRefBaru, dataDaftarSiswaBaru);
        // Daftar mata pelajaran
        List<String> mataPelajaranBaru = [
          "Pendidikan Pancasila dan Kewarganegaraan (PPKn)",
          "Ilmu Pengetahuan Alam dan Sosial (IPAS)",
          "Bahasa Indonesia",
          "Pendidikan Agama Islam dan Budi Pekerti",
          "Matematika",
          "Pendidikan Jasmani, Olahraga, dan Kesehatan (PJOK)",
          "Bahasa Inggris",
        ];
        // Tambahkan mata pelajaran ke batch
        for (String pelajaran in mataPelajaranBaru) {
          Map<String, dynamic> dataMataPelajaranBaru = _createDataMap(
            namaKelas: argumentKelas,
            fase: faseNya,
            tahunAjaran: tahunajaranya,
            walikelas: waliKelasSiswaC.text,
            idwalikelas: uidWaliKelasnya,
            namamatapelajaran: pelajaran,
          );
          batch.set(
            daftarSiswaDocRefBaru.collection('matapelajaran').doc(pelajaran),
            dataMataPelajaranBaru,
          );
        }
        // Commit batch
        await batch.commit();
        // Panggil fungsi lain
        await tambahDaftarKelasGuruAjar();
        await kelasUntukSiswaNext(nisnSiswa, namaSiswa);
        await ubahStatusSiswaNext(nisnSiswa);
      }
    } catch (e) {
      // Tangani error yang lebih spesifik
      if (e is FirebaseException) {
        print('FirebaseException: ${e.code} - ${e.message}');
        Get.snackbar(
          'Error Firestore',
          'Terjadi kesalahan Firestore: ${e.message}',
        );
      } else {
        print('Exception: $e');
        Get.snackbar('Error', 'Terjadi kesalahan: $e');
      }
    }
  }

  Future<void> simpanKelasBaruLagi(String namaSiswa, String nisnSiswa) async {
    isLoadingTambahKelas.value = true;

    // Mulai loading
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    String kelasNya = argumentKelas.substring(0, 1);
    String namaSemesternya = "Semester I";
    String faseNya =
        (kelasNya == '1' || kelasNya == '2')
            ? "Fase A"
            : (kelasNya == '3' || kelasNya == '4')
            ? "Fase B"
            : "Fase C";

    CollectionReference<Map<String, dynamic>> colKelas = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelastahunajaran');
    DocumentSnapshot<Map<String, dynamic>> docIdKelas =
        await colKelas.doc(argumentKelas).get();

    // Helper function untuk membuat data map yang konsisten
    Map<String, dynamic> _createDataMap({
      required String namasemester,
      required String namaKelas,
      required String fase,
      required String tahunAjaran,
      required String walikelas,
      required String idwalikelas,
      String? namaSiswa,
      String? nisn,
      String? namamatapelajaran,
    }) {
      return {
        'namakelas': namaKelas,
        'namasemester' : namasemester,
        'fase': fase,
        'tahunajaran': tahunAjaran,
        'walikelas': walikelas,
        'idwalikelas': idwalikelas,
        'emailpenginput': emailAdmin,
        'idpenginput': idUser,
        'tanggalinput': DateTime.now().toIso8601String(),
        if (namaSiswa != null) 'namasiswa': namaSiswa,
        if (nisn != null) 'nisn': nisn,
        if (namamatapelajaran != null) 'namamatapelajaran': namamatapelajaran,
      };
    }

    WriteBatch batch = firestore.batch();
    try {
      if (docIdKelas.exists) {
        // Ambil data wali kelas dan ID wali kelas dari dokumen kelas
        String walikelas = docIdKelas.data()!['walikelas'];
        String idwalikelas = docIdKelas.data()!['idwalikelas'];

        // Data untuk kelas
        Map<String, dynamic> dataKelas = _createDataMap(
          namaKelas: argumentKelas,
          namasemester: namaSemesternya,
          fase: faseNya,
          tahunAjaran: tahunajaranya,
          walikelas: walikelas,
          idwalikelas: idwalikelas,
        );

        //Data untuk daftar siswa
        Map<String, dynamic> dataDaftarSiswa = {
          ..._createDataMap(
            namaKelas: argumentKelas,
            namasemester: namaSemesternya,
            fase: faseNya,
            tahunAjaran: tahunajaranya,
            walikelas: walikelas,
            idwalikelas: idwalikelas,
            namaSiswa: namaSiswa,
            nisn: nisnSiswa,
          ),
          'status': 'aktif',
          'idsiswa': nisnSiswa,
          'statuskelompok': 'baru',
        };

        // Referensi dokumen yang akan diubah
        DocumentReference kelasDocRef = colKelas.doc(argumentKelas);
        DocumentReference daftarSiswaDocRef = kelasDocRef
            .collection('daftarsiswa')
            .doc(nisnSiswa);

        //Data untuk semester
        Map<String, dynamic> dataSemester = _createDataMap(
          namaKelas: argumentKelas,
          namasemester: namaSemesternya,
          fase: faseNya,
          tahunAjaran: tahunajaranya,
          walikelas: walikelas,
          idwalikelas: idwalikelas,
        );
        DocumentReference semesterDocRef = daftarSiswaDocRef
            .collection('semester')
            .doc('Semester I');

        // Tambahkan operasi ke batch
        batch.set(kelasDocRef, dataKelas);
        batch.set(daftarSiswaDocRef, dataDaftarSiswa);
        batch.set(semesterDocRef, dataSemester);

        // Daftar mata pelajaran
        List<String> mataPelajaran = [
          "Pendidikan Pancasila dan Kewarganegaraan (PPKn)",
          "Ilmu Pengetahuan Alam dan Sosial (IPAS)",
          "Bahasa Indonesia",
          "Pendidikan Agama Islam dan Budi Pekerti",
          "Matematika",
          "Pendidikan Jasmani, Olahraga, dan Kesehatan (PJOK)",
          "Bahasa Inggris",
        ];

        // Tambahkan mata pelajaran ke batch
        for (String pelajaran in mataPelajaran) {
          Map<String, dynamic> dataMataPelajaran = _createDataMap(
            namaKelas: argumentKelas,
            namasemester: namaSemesternya,
            fase: faseNya,
            tahunAjaran: tahunajaranya,
            walikelas: walikelas,
            idwalikelas: idwalikelas,
            namamatapelajaran: pelajaran,
          );
          batch.set(
            semesterDocRef.collection('matapelajaran').doc(pelajaran),
            dataMataPelajaran,
          );
        }

        // Commit batch
        await batch.commit();

        // Panggil fungsi lain
        await tambahDaftarKelasGuruAjar();
        await kelasUntukSiswaNext(nisnSiswa, namaSiswa);
        await ubahStatusSiswaNext(nisnSiswa);
      } else {
        // Jika Dokumen kelas tidak ditemukan -> buat data kelas baru
        QuerySnapshot<Map<String, dynamic>> querySnapshot =
            await firestore
                .collection('Sekolah')
                .doc(idSekolah)
                .collection('pegawai')
                .where('alias', isEqualTo: waliKelasSiswaC.text)
                .get();
        if (querySnapshot.docs.isEmpty) {
          Get.snackbar('Error', 'Wali kelas tidak ditemukan.');
          return;
        }
        String uidWaliKelasnya = querySnapshot.docs.first.data()!['uid'];

        // Cek apakah wali kelas sudah ada di kelas lain
        QuerySnapshot<Map<String, dynamic>> snapKelas = await colKelas.get();
        List<String> waliKelasBaruList =
            snapKelas.docs
                .where((doc) => doc.data()!['walikelas'] != null)
                .map((doc) => doc.data()!['walikelas'] as String)
                .toList();
        if (waliKelasBaruList.contains(waliKelasSiswaC.text)) {
          Get.snackbar(
            'Error',
            'Wali kelas sudah ada di kelas lain, silakan pilih yang lain.',
          );
          return;
        }

        // Jika semua validasi lolos, buat data kelas baru
        Map<String, dynamic> dataKelasBaru = _createDataMap(
          namaKelas: argumentKelas,
          namasemester: namaSemesternya,
          fase: faseNya,
          tahunAjaran: tahunajaranya,
          walikelas: waliKelasSiswaC.text,
          idwalikelas: uidWaliKelasnya,
        );

        //Data untuk daftar siswa
        Map<String, dynamic> dataDaftarSiswaBaru = {
          ..._createDataMap(
            namaKelas: argumentKelas,
            namasemester: namaSemesternya,
            fase: faseNya,
            tahunAjaran: tahunajaranya,
            walikelas: waliKelasSiswaC.text,
            idwalikelas: uidWaliKelasnya,
            namaSiswa: namaSiswa,
            nisn: nisnSiswa,
          ),
          'status': 'aktif',
          'idsiswa': nisnSiswa,
          'statuskelompok': 'baru',
        };

        // Referensi dokumen yang akan diubah
        DocumentReference kelasDocRefBaru = colKelas.doc(argumentKelas);
        DocumentReference daftarSiswaDocRefBaru = kelasDocRefBaru
            .collection('daftarsiswa')
            .doc(nisnSiswa);

        //Data untuk semester
        Map<String, dynamic> dataSemesterBaru = _createDataMap(
          namaKelas: argumentKelas,
          namasemester: namaSemesternya,
          fase: faseNya,
          tahunAjaran: tahunajaranya,
          walikelas: waliKelasSiswaC.text,
          idwalikelas: uidWaliKelasnya,
        );
        DocumentReference semesterDocRefBaru = daftarSiswaDocRefBaru
            .collection('semester')
            .doc('Semester I');

        // Tambahkan operasi ke batch
        batch.set(kelasDocRefBaru, dataKelasBaru);
        batch.set(daftarSiswaDocRefBaru, dataDaftarSiswaBaru);
        batch.set(semesterDocRefBaru, dataSemesterBaru);

        // Daftar mata pelajaran
        List<String> mataPelajaranBaru = [
          "Pendidikan Pancasila dan Kewarganegaraan (PPKn)",
          "Ilmu Pengetahuan Alam dan Sosial (IPAS)",
          "Bahasa Indonesia",
          "Pendidikan Agama Islam dan Budi Pekerti",
          "Matematika",
          "Pendidikan Jasmani, Olahraga, dan Kesehatan (PJOK)",
          "Bahasa Inggris",
        ];

        // Tambahkan mata pelajaran ke batch
        for (String pelajaran in mataPelajaranBaru) {
          Map<String, dynamic> dataMataPelajaranBaru = _createDataMap(
            namaKelas: argumentKelas,
            namasemester: namaSemesternya,
            fase: faseNya,
            tahunAjaran: tahunajaranya,
            walikelas: waliKelasSiswaC.text,
            idwalikelas: uidWaliKelasnya,
            namamatapelajaran: pelajaran,
          );
          batch.set(
            semesterDocRefBaru.collection('matapelajaran').doc(pelajaran),
            dataMataPelajaranBaru,
          );
        }

        // Commit batch
        await batch.commit();

        // Panggil fungsi lain
        await firestore.collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelasaktif')
          .doc(argumentKelas)
          .set({
            'namakelas': argumentKelas,
            'fase': faseNya,
            'tahunajaran' : tahunajaranya,
            'emailpenginput' : emailAdmin,
            'idpenginput' : idUser,
          });
        await tambahDaftarKelasGuruAjar();
        await kelasUntukSiswaNext(nisnSiswa, namaSiswa);
        await ubahStatusSiswaNext(nisnSiswa);
      }
    } catch (e) {
      // Tangani error yang lebih spesifik
      if (e is FirebaseException) {
        // print('FirebaseException: ${e.code} - ${e.message}');
        Get.snackbar(
          'Error Firestore',
          'Terjadi kesalahan Firestore: ${e.message}',
        );
      } else {
        // print('Exception: $e');
        Get.snackbar('Error', 'Terjadi kesalahan: $e');
      }
    } finally {
      isLoadingTambahKelas.value = false;
      // Selesai loading
    }
  }


}
//==========================================================================================================================================================



// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get/get.dart';
// import 'package:flutter/material.dart';

// class PemberianKelasSiswaController extends GetxController {
//   // Konstanta untuk nama koleksi dan dokumen
//   static const String SEKOLAH = 'Sekolah';
//   static const String TAHUN_AJARAN = 'tahunajaran';
//   static const String KELAS_TAHUN_AJARAN = 'kelastahunajaran';
//   static const String SEMESTER = 'semester';
//   static const String DAFTAR_SISWA = 'daftarsiswa';
//   static const String MATA_PELAJARAN = 'matapelajaran';
//   static const String SEMESTER_I = 'Semester I';
//   static const String SISWA = 'siswa';
//   static const String PEGAWAI = 'pegawai';

//   // Variabel RX
//   RxBool isLoading = false.obs;
//   RxBool isLoadingTambahKelas = false.obs;

//   // Controller untuk wali kelas
//   TextEditingController waliKelasSiswaC = TextEditingController();
//   TextEditingController namaTahunAjaranTerakhirC = TextEditingController();
//   TextEditingController idPegawaiC = TextEditingController();

//   // Firebase
//   FirebaseAuth auth = FirebaseAuth.instance;
//   FirebaseFirestore firestore = FirebaseFirestore.instance;

//   // Identifiers
//   String idUser = FirebaseAuth.instance.currentUser!.uid;
//   String idSekolah = '20404148';
//   String emailAdmin = FirebaseAuth.instance.currentUser!.email!;
//   String get argumentKelas => Get.arguments.toString();

//   // Stream untuk menampilkan siswa
//   late Stream<QuerySnapshot<Map<String, dynamic>>> tampilkanSiswa;
//   @override
//   void onInit() {
//     super.onInit();
//     tampilkanSiswa =
//         firestore
//             .collection(SEKOLAH)
//             .doc(idSekolah)
//             .collection(SISWA)
//             .where('status', isNotEqualTo: 'aktif')
//             .snapshots();
//   }

//   // Helper function untuk mendapatkan tahun ajaran terakhir
//   Future<String> getTahunAjaranTerakhir() async {
//     final snapshot =
//         await firestore
//             .collection(SEKOLAH)
//             .doc(idSekolah)
//             .collection(TAHUN_AJARAN)
//             .get();
//     return snapshot.docs
//         .map((e) => e.data()['namatahunajaran'] as String)
//         .toList()
//         .last;
//   }

//   // Helper function untuk mendapatkan UID wali kelas
//   Future<String?> _getUidWaliKelas(String aliasWaliKelas) async {
//     final querySnapshot =
//         await firestore
//             .collection(SEKOLAH)
//             .doc(idSekolah)
//             .collection(PEGAWAI)
//             .where('alias', isEqualTo: aliasWaliKelas)
//             .get();

//     if (querySnapshot.docs.isNotEmpty) {
//       return querySnapshot.docs.first.data()['uid'] as String?;
//     }
//     return null;
//   }

//   // Helper function untuk membuat data kelas, semester, dan siswa
//   Map<String, dynamic> _createDataMap({
//     required String namaKelas,
//     required String fase,
//     required String tahunAjaran,
//     required String? walikelas,
//     required String? idwalikelas,
//     String? namaSiswa,
//     String? nisnSiswa,
//   }) {
//     return {
//       'namakelas': namaKelas,
//       'fase': fase,
//       'tahunajaran': tahunAjaran,
//       'emailpenginput': emailAdmin,
//       'idpenginput': idUser,
//       'tanggalinput': DateTime.now().toIso8601String(),
//       if (walikelas != null) 'walikelas': walikelas,
//       if (idwalikelas != null) 'idwalikelas': idwalikelas,
//       if (namaSiswa != null) 'namasiswa': namaSiswa,
//       if (nisnSiswa != null) 'nisn': nisnSiswa,
//       if (namaSiswa != null && nisnSiswa != null) 'status': 'aktif',
//       if (namaSiswa != null && nisnSiswa != null) 'idsiswa': nisnSiswa,
//       if (namaSiswa != null && nisnSiswa != null) 'statuskelompok': 'baru',
//     };
//   }

//   Future<void> simpanKelasSiswa(String namaSiswa, String nisnSiswa) async {
//     isLoadingTambahKelas.value = true;
//     try {
//       final tahunajaranya = await getTahunAjaranTerakhir();
//       final idTahunAjaran = tahunajaranya.replaceAll("/", "-");
//       final kelasNya = argumentKelas.substring(0, 1);
//       final faseNya =
//           (kelasNya == '1' || kelasNya == '2')
//               ? "Fase A"
//               : (kelasNya == '3' || kelasNya == '4')
//               ? "Fase B"
//               : "Fase C";
//       final docIdKelas =
//           await firestore
//               .collection(SEKOLAH)
//               .doc(idSekolah)
//               .collection(TAHUN_AJARAN)
//               .doc(idTahunAjaran)
//               .collection(KELAS_TAHUN_AJARAN)
//               .doc(argumentKelas)
//               .get();
//       final walikelas = docIdKelas.data()?['walikelas'] as String?;
//       final idwalikelas = docIdKelas.data()?['idwalikelas'] as String?;
//       if (docIdKelas.exists && walikelas != null && idwalikelas != null) {
//         final batch = firestore.batch();
//         // Data kelas
//         final dataKelas = _createDataMap(
//           namaKelas: argumentKelas,
//           fase: faseNya,
//           tahunAjaran: tahunajaranya,
//           walikelas: walikelas,
//           idwalikelas: idwalikelas,
//         );
//         // Data semester
//         final dataSemester = _createDataMap(
//           namaKelas: argumentKelas,
//           fase: faseNya,
//           tahunAjaran: tahunajaranya,
//           walikelas: walikelas,
//           idwalikelas: idwalikelas,
//         );
//         // Data siswa
//         final dataSiswa = _createDataMap(
//           namaKelas: argumentKelas,
//           fase: faseNya,
//           tahunAjaran: tahunajaranya,
//           walikelas: walikelas,
//           idwalikelas: idwalikelas,
//           namaSiswa: namaSiswa,
//           nisnSiswa: nisnSiswa,
//         );
//         // Mata pelajaran
//         const daftarMataPelajaran = [
//           "Pendidikan Pancasila dan Kewarganegaraan (PPKn)",
//           "Ilmu Pengetahuan Alam dan Sosial (IPAS)",
//           "Bahasa Indonesia",
//           "Pendidikan Agama Islam dan Budi Pekerti",
//           "Matematika",
//           "Pendidikan Jasmani, Olahraga, dan Kesehatan (PJOK)",
//           "Bahasa Inggris",
//         ];
//         // Referensi dokumen
//         final kelasDocRef = firestore
//             .collection(SEKOLAH)
//             .doc(idSekolah)
//             .collection(TAHUN_AJARAN)
//             .doc(idTahunAjaran)
//             .collection(KELAS_TAHUN_AJARAN)
//             .doc(argumentKelas);
//         final semesterDocRef = kelasDocRef.collection(SEMESTER).doc(SEMESTER_I);
//         final siswaDocRef = semesterDocRef
//             .collection(DAFTAR_SISWA)
//             .doc(nisnSiswa);
//         // Set data ke Firestore menggunakan batch
//         batch.set(kelasDocRef, dataKelas);
//         batch.set(semesterDocRef, dataSemester);
//         batch.set(siswaDocRef, dataSiswa);
//         // Tambahkan mata pelajaran ke batch
//         for (final mataPelajaran in daftarMataPelajaran) {
//           final dataMataPelajaran = _createDataMap(
//             namaKelas: argumentKelas,
//             fase: faseNya,
//             tahunAjaran: tahunajaranya,
//             walikelas: walikelas,
//             idwalikelas: idwalikelas,
//           );
//           batch.set(
//             siswaDocRef.collection(MATA_PELAJARAN).doc(mataPelajaran),
//             dataMataPelajaran,
//           );
//         }
//         // Commit batch
//         await batch.commit();
//         // Jalankan fungsi tambahan
//         await tambahDaftarKelasGuruAjar();
//         await kelasUntukSiswaNext(nisnSiswa, namaSiswa);
//         await ubahStatusSiswaNext(nisnSiswa);
//       } else {
//         // Tangani kasus ketika dokumen kelas tidak ada
//         Get.snackbar('Error', 'kelas tidak ada');
//       }
//     } catch (e) {
//       // Tangani kesalahan
//       Get.snackbar('Error', 'Terjadi kesalahan: $e');
//     } finally {
//       isLoadingTambahKelas.value = false;
//     }
//   }

//   Future<void> tambahDaftarKelasGuruAjar() async {
//     String tahunajaranya = await getTahunAjaranTerakhir();
//     String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
//     String kelasNya = argumentKelas.substring(0, 1);
//     String faseNya =
//         (kelasNya == '1' || kelasNya == '2')
//             ? "Fase A"
//             : (kelasNya == '3' || kelasNya == '4')
//             ? "Fase B"
//             : "Fase C";
//     //ambil data guru terpilih
//     QuerySnapshot<Map<String, dynamic>> querySnapshotGuru =
//         await firestore
//             .collection('Sekolah')
//             .doc(idSekolah)
//             .collection('pegawai')
//             .where('alias', isEqualTo: waliKelasSiswaC.text)
//             .get();
//     if (querySnapshotGuru.docs.isNotEmpty) {
//       Map<String, dynamic> dataGuru = querySnapshotGuru.docs.first.data();
//       String uidGuru = dataGuru['uid'];
//       await firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('pegawai')
//           .doc(uidGuru)
//           .collection('tahunajaran')
//           .doc(idTahunAjaran)
//           .set({
//             'namatahunajaran': tahunajaranya,
//             'idpenginput': idUser,
//             'tanggalinput': DateTime.now().toIso8601String(),
//           });
//       await firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('pegawai')
//           .doc(uidGuru)
//           .collection('tahunajaran')
//           .doc(idTahunAjaran)
//           .collection('kelasnya')
//           .doc(argumentKelas)
//           .set({
//             'namakelas': argumentKelas,
//             'fase': faseNya,
//             'tahunajaran': tahunajaranya,
//             'emailpenginput': emailAdmin,
//             'idpenginput': idUser,
//             'tanggalinput': DateTime.now().toIso8601String(),
//           });
//     }
//   }

//   Future<void> kelasUntukSiswaNext(String nisnSiswa, String namaSiswa) async {
//     String tahunajaranya = await getTahunAjaranTerakhir();
//     String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
//     String kelasNya = argumentKelas.substring(0, 1);
//     String faseNya =
//         (kelasNya == '1' || kelasNya == '2')
//             ? "Fase A"
//             : (kelasNya == '3' || kelasNya == '4')
//             ? "Fase B"
//             : "Fase C";
//     await firestore
//         .collection('Sekolah')
//         .doc(idSekolah)
//         .collection('siswa')
//         .doc(nisnSiswa)
//         .collection('tahunajaran')
//         .doc(idTahunAjaran)
//         .set({
//           'fase': faseNya,
//           'nisn': nisnSiswa,
//           'namatahunajaran': tahunajaranya,
//           'idpenginput': idUser,
//           'tanggalinput': DateTime.now().toIso8601String(),
//         });
//     await firestore
//         .collection('Sekolah')
//         .doc(idSekolah)
//         .collection('siswa')
//         .doc(nisnSiswa)
//         .collection('tahunajaran')
//         .doc(idTahunAjaran)
//         .collection('kelasnya')
//         .doc(argumentKelas)
//         .set({
//           'namasiswa': namaSiswa,
//           'nisn': nisnSiswa,
//           'namakelas': argumentKelas,
//           'fase': faseNya,
//           'tahunajaran': tahunajaranya,
//           'emailpenginput': emailAdmin,
//           'idpenginput': idUser,
//           'tanggalinput': DateTime.now().toIso8601String(),
//         }); // }
//   }

//   Future<void> ubahStatusSiswaNext(String nisnSiSwa) async {
//     await firestore
//         .collection('Sekolah')
//         .doc(idSekolah)
//         .collection('siswa')
//         .doc(nisnSiSwa)
//         .update({'status': 'aktif'});
  
// }

//   Future<List<String>> getDataWaliKelasBaru() async {
//     List<String> waliKelasBaruList = [];

//     String tahunajaranya = await getTahunAjaranTerakhir();
//     String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

//     QuerySnapshot<Map<String, dynamic>> snapKelas =
//         await firestore
//             .collection('Sekolah')
//             .doc(idSekolah)
//             .collection('tahunajaran')
//             .doc(idTahunAjaran)
//             .collection('kelastahunajaran')
//             .get();

//     String namaWalikelas =
//         snapKelas.docs.isNotEmpty
//             ? snapKelas.docs.first.data()['walikelas']
//             : '';

//     await firestore
//         .collection('Sekolah')
//         .doc(idSekolah)
//         .collection('pegawai')
//         .where('alias', isNotEqualTo: namaWalikelas)
//         .get()
//         .then((querySnapshot) {
//           for (var docSnapshot in querySnapshot.docs.where(
//             (doc) => doc['role'] == 'Guru Kelas',
//           )) {
//             waliKelasBaruList.add(docSnapshot.data()['alias']);
//             // waliKelasBaruList.add(docSnapshot.data()['nip']);
//           }
//         });
//     return waliKelasBaruList;
//   }



//     Future<QuerySnapshot<Map<String, dynamic>>> getDataWali() async {
//     String tahunajaranya = await getTahunAjaranTerakhir();
//     String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

//     CollectionReference<Map<String, dynamic>> colKelas = firestore
//         .collection('Sekolah')
//         .doc(idSekolah)
//         .collection('tahunajaran')
//         .doc(idTahunAjaran)
//         .collection('kelastahunajaran');

//     try {
//       return await colKelas.get();
//       // Example return statement
//     } catch (e) {
//       // print('Error occurred: $e');
//       throw Exception('Failed to fetch data: $e');
//     }
//   }
// }
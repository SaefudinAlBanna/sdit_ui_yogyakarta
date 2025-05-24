import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:intl/intl.dart';

class DaftarHalaqohController extends GetxController {
  var dataFase = Get.arguments;
  RxBool isLoading = false.obs;

  TextEditingController pengampuC = TextEditingController();
  TextEditingController kelasSiswaC = TextEditingController();
  TextEditingController alasanC = TextEditingController();
  TextEditingController umiC = TextEditingController();

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String idUser = FirebaseAuth.instance.currentUser!.uid;
  String idSekolah = '20404148';
  String emailAdmin = FirebaseAuth.instance.currentUser!.email!;

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

  Future<List<String>> getDataKelasYangAda() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    List<String> kelasList = [];
    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelastahunajaran')
        .where('fase', isEqualTo: dataFase['fase'])
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            kelasList.add(docSnapshot.id);
          }
        });
    return kelasList;
  }

  Future<List<String>> getDataUmi() async {
    List<String> umiList = ['Umi', 'AlQuran'];
    return umiList;
  }

  Future<void> updateUmi(String nisnSiswa) async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    // String idSekolah = '20404148';

    if (idTahunAjaran.isNotEmpty) {
      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelompokmengaji')
          .doc(dataFase['fase'])
          .collection('pengampu')
          .doc(dataFase['namapengampu'])
          .collection('tempat')
          .doc(dataFase['tempatmengaji'])
          .collection('daftarsiswa')
          .doc(nisnSiswa)
          .collection('semester')
          .doc('Semester I')
          .update({'ummi': umiC.text});

      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('siswa')
          .doc(nisnSiswa)
          .collection('tahunajarankelompok')
          .doc(idTahunAjaran)
          // .collection('semester')
          // .doc(argumenData[0]['namasemester'])
          .collection('kelompokmengaji')
          .doc(dataFase['fase'])
          .collection('pengampu')
          .doc(dataFase['namapengampu'])
          .collection('tempat')
          .doc(dataFase['tempatmengaji'])
          .collection('semester')
          .doc('Semester I')
          .update({'ummi': umiC.text});

      Get.back();
      Get.snackbar("Berhasil", "Umi Berhasil dibuat");
    } else {
      Get.snackbar(
        "Error",
        "Data tidak ditemukan, Atau periksa koneksi internet",
      );
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getDataSiswaStreamBaru() async* {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    // String idSemester = await getDataSemester();
    yield* firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelastahunajaran')
        .doc(kelasSiswaC.text)
        .collection('daftarsiswa')
        // .collection('semester')
        // .doc('Semester I') // ini nanti diganti otomatis // sudah di pasang -->> kalo sudah dihapus comment
        // .collection('daftarsiswa')
        .where('statuskelompok', isEqualTo: 'baru')
        .snapshots();

    // print('ini kelasnya : ${kelasSiswaC.text}');
  }

  Future<void> halaqohUntukSiswaNext(String nisnSiswa) async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    QuerySnapshot<Map<String, dynamic>> querySnapshotKelompok =
        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('pegawai')
            .where('alias', isEqualTo: dataFase['namapengampu'])
            .get();
    if (querySnapshotKelompok.docs.isNotEmpty) {
      Map<String, dynamic> dataGuru = querySnapshotKelompok.docs.first.data();
      String idPengampu = dataGuru['uid'];

      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('siswa')
          .doc(nisnSiswa)
          .collection('tahunajarankelompok')
          .doc(idTahunAjaran)
          .set({
            'fase': dataFase['fase'],
            'namatahunajaran': tahunajaranya,
            'idpenginput': idUser,
            'tanggalinput': DateTime.now().toIso8601String(),
          });

      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('siswa')
          .doc(nisnSiswa)
          .collection('tahunajarankelompok')
          .doc(idTahunAjaran)
          .collection('semester')
          .doc(dataFase['namasemester'])
          .set({
            'fase': dataFase['fase'],
            'namasemester': dataFase['namasemester'],
            'tahunajaran': tahunajaranya,
            'emailpenginput': emailAdmin,
            'idpenginput': idUser,
            'tanggalinput': DateTime.now().toIso8601String(),
          });

      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('siswa')
          .doc(nisnSiswa)
          .collection('tahunajarankelompok')
          .doc(idTahunAjaran)
          .collection('semester')
          .doc(dataFase['namasemester'])
          .collection('kelompokmengaji')
          .doc(dataFase['fase'])
          .set({
            'fase': dataFase['fase'],
            'tempatmengaji': dataFase['tempatmengaji'],
            'namapengampu': dataFase['namapengampu'],
            'kelompokmengaji': dataFase['namapengampu'],
            'idpengampu': idPengampu,
            'namasemester': dataFase['namasemester'],
            'tahunajaran': tahunajaranya,
            'emailpenginput': emailAdmin,
            'idpenginput': idUser,
            'tanggalinput': DateTime.now().toIso8601String(),
          });

      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('siswa')
          .doc(nisnSiswa)
          .collection('tahunajarankelompok')
          .doc(idTahunAjaran)
          .collection('semester')
          .doc(dataFase['namasemester'])
          .collection('kelompokmengaji')
          .doc(dataFase['fase'])
          .collection('tempat')
          .doc(dataFase['tempatmengaji'])
          .set({
            'nisn': nisnSiswa,
            'tempatmengaji': dataFase['tempatmengaji'],
            'fase': dataFase['fase'],
            'tahunajaran': dataFase['tahunajaran'],
            'kelompokmengaji': dataFase['namapengampu'],
            'namasemester': dataFase['namasemester'],
            'namapengampu': dataFase['namapengampu'],
            'idpengampu': idPengampu,
            'emailpenginput': emailAdmin,
            'idpenginput': idUser,
            'tanggalinput': DateTime.now().toIso8601String(),
          });
    }
  }

  Future<void> ubahStatusSiswa(String nisnSiSwa) async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelastahunajaran')
        .doc(kelasSiswaC.text)
        .collection('daftarsiswa')
        .doc(nisnSiSwa)
        .update({'statuskelompok': 'aktif'});
  }

  Future<void> simpanSiswaKelompok(String namaSiswa, String nisnSiswa) async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    QuerySnapshot<Map<String, dynamic>> querySnapshotKelompok =
        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('pegawai')
            .where('alias', isEqualTo: dataFase['namapengampu'])
            .get();
    if (querySnapshotKelompok.docs.isNotEmpty) {
      Map<String, dynamic> dataGuru = querySnapshotKelompok.docs.first.data();
      String idPengampu = dataGuru['uid'];

      //buat pada tahunpelajaran sekolah
      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelompokmengaji')
          .doc(dataFase['fase'])
          .collection('pengampu')
          .doc(dataFase['namapengampu'])
          .collection('tempat')
          .doc(dataFase['tempatmengaji'])
          .collection('daftarsiswa')
          .doc(nisnSiswa)
          .set({
            'namasiswa': namaSiswa,
            'nisn': nisnSiswa,
            'kelas': kelasSiswaC.text,
            'fase': dataFase['fase'],
            'tempatmengaji': dataFase['tempatmengaji'],
            'tahunajaran': dataFase['tahunajaran'],
            'kelompokmengaji': dataFase['namapengampu'],
            'namapengampu': dataFase['namapengampu'],
            'idpengampu': dataFase['idpengampu'],
            'emailpenginput': emailAdmin,
            'idpenginput': idUser,
            'tanggalinput': DateTime.now().toIso8601String(),
            'idsiswa': nisnSiswa,
          });

      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelompokmengaji')
          .doc(dataFase['fase'])
          .collection('pengampu')
          .doc(dataFase['namapengampu'])
          .collection('tempat')
          .doc(dataFase['tempatmengaji'])
          .collection('daftarsiswa')
          .doc(nisnSiswa)
          .collection('semester')
          .doc('Semester I')
          .set({
            'ummi': "0",
            'namasiswa': namaSiswa,
            'nisn': nisnSiswa,
            'kelas': kelasSiswaC.text,
            'fase': dataFase['fase'],
            'tempatmengaji': dataFase['tempatmengaji'],
            'tahunajaran': dataFase['tahunajaran'],
            'kelompokmengaji': dataFase['namapengampu'],
            'namasemester': 'Semester I',
            'namapengampu': dataFase['namapengampu'],
            'idpengampu': idPengampu,
            'emailpenginput': emailAdmin,
            'idpenginput': idUser,
            'tanggalinput': DateTime.now().toIso8601String(),
            'idsiswa': nisnSiswa,
          });

      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('siswa')
          .doc(nisnSiswa)
          .collection('tahunajarankelompok')
          .doc(idTahunAjaran)
          .set({
            'fase': dataFase['fase'],
            'nisn': nisnSiswa,
            'namatahunajaran': tahunajaranya,
            'idpenginput': idUser,
            'tanggalinput': DateTime.now().toIso8601String(),
          });

      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('siswa')
          .doc(nisnSiswa)
          .collection('tahunajarankelompok')
          .doc(idTahunAjaran)
          // .collection('semester')
          // .doc(argumenData[0]['namasemester'])
          .collection('kelompokmengaji')
          .doc(dataFase['fase'])
          .set({
            'fase': dataFase['fase'],
            'tempatmengaji': dataFase['tempatmengaji'],
            'namapengampu': dataFase['namapengampu'],
            'kelompokmengaji': dataFase['namapengampu'],
            'idpengampu': idPengampu,
            // 'namasemester': argumenData[0]['namasemester'],
            'tahunajaran': tahunajaranya,
            'emailpenginput': emailAdmin,
            'idpenginput': idUser,
            'tanggalinput': DateTime.now().toIso8601String(),
          });

      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('siswa')
          .doc(nisnSiswa)
          .collection('tahunajarankelompok')
          .doc(idTahunAjaran)
          .collection('kelompokmengaji')
          .doc(dataFase['fase'])
          .collection('pengampu')
          .doc(dataFase['namapengampu'])
          .set({
            'nisn': nisnSiswa,
            // 'tempatmengaji': dataFase['tempatmengaji'],
            'fase': dataFase['fase'],
            'tahunajaran': idTahunAjaran,
            'kelompokmengaji': dataFase['namapengampu'],
            'namapengampu': dataFase['namapengampu'],
            'idpengampu': idPengampu,
            'emailpenginput': emailAdmin,
            'idpenginput': idUser,
            'tanggalinput': DateTime.now().toIso8601String(),
          });

      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('siswa')
          .doc(nisnSiswa)
          .collection('tahunajarankelompok')
          .doc(idTahunAjaran)
          .collection('kelompokmengaji')
          .doc(dataFase['fase'])
          .collection('pengampu')
          .doc(dataFase['namapengampu'])
          .collection('tempat')
          .doc(dataFase['tempatmengaji'])
          .set({
            'nisn': nisnSiswa,
            'tempatmengaji': dataFase['tempatmengaji'],
            'fase': dataFase['fase'],
            'tahunajaran': idTahunAjaran,
            'kelompokmengaji': dataFase['namapengampu'],
            // 'namasemester': 'Semester I',
            'namapengampu': dataFase['namapengampu'],
            'idpengampu': idPengampu,
            'emailpenginput': emailAdmin,
            'idpenginput': idUser,
            'tanggalinput': DateTime.now().toIso8601String(),
          });

      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('siswa')
          .doc(nisnSiswa)
          .collection('tahunajarankelompok')
          .doc(idTahunAjaran)
          // .collection('semester')
          // .doc(argumenData[0]['namasemester'])
          .collection('kelompokmengaji')
          .doc(dataFase['fase'])
          .collection('pengampu')
          .doc(dataFase['namapengampu'])
          .collection('tempat')
          .doc(dataFase['tempatmengaji'])
          .collection('semester')
          .doc('Semester I')
          .set({
            'ummi': "0",
            'nisn': nisnSiswa,
            'tempatmengaji': dataFase['tempatmengaji'],
            'fase': dataFase['fase'],
            'tahunajaran': idTahunAjaran,
            'kelompokmengaji': dataFase['namapengampu'],
            'namasemester': 'Semester I',
            'namapengampu': dataFase['namapengampu'],
            'idpengampu': idPengampu,
            'emailpenginput': emailAdmin,
            'idpenginput': idUser,
            'tanggalinput': DateTime.now().toIso8601String(),
          });

      // halaqohUntukSiswaNext(nisnSiswa);
      ubahStatusSiswa(nisnSiswa);
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getDaftarHalaqoh() async* {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    yield* firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        // .collection('semester')
        // .doc(dataFase['namasemester'])
        .collection('kelompokmengaji')
        .doc(dataFase['fase']) // ini nanti diganti otomatis
        .collection('pengampu')
        .doc(dataFase['namapengampu'])
        .collection('tempat')
        .doc(dataFase['tempatmengaji'])
        .collection('daftarsiswa')
        .snapshots();
  }

  Future<List<String>> getDataPengampuFase() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    List<String> pengampuList = [];
    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('semester')
        .doc(dataFase['namasemester'])
        .collection('kelompokmengaji')
        .doc(dataFase['fase'])
        .collection('pengampu')
        .where('namapengampu', isNotEqualTo: dataFase['namapengampu'])
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs.where(
            (doc) => doc['fase'] == dataFase['fase'],
          )) {
            pengampuList.add(docSnapshot.data()['namapengampu']);
          }
        });
    return pengampuList;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> dataPengampuPindah() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    DocumentSnapshot<Map<String, dynamic>> getPengampuNya =
        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('tahunajaran')
            .doc(idTahunAjaran)
            .collection('semester')
            .doc(dataFase['namasemester'])
            .collection('kelompokmengaji')
            .doc(dataFase['fase'])
            .collection('pengampu')
            // .where('namapengampu', isNotEqualTo: dataFase['namapengampu'])
            .doc(pengampuC.text)
            .get();

    // print('ini get pentampunya = ${getPengampuNya.docs.first.data()['test']}');
    return getPengampuNya;
  }

  Future<void> pindahkan(String nisnSiswa) async {
    if (pengampuC.text.isEmpty || pengampuC.text == "") {
      // print('PENGAMPU BELUM DIISI');
      isLoading.value = false;
      Get.snackbar('Peringatan', 'Pengampu baru kosong');
    } else if (alasanC.text.isEmpty) {
      isLoading.value = false;
      Get.snackbar('Peringatan', 'Alasan pindah kosong, silahkan diisi dahulu');
    } else {
      isLoading.value = true;

      DocumentSnapshot<Map<String, dynamic>> pengampuSnapshot =
          await dataPengampuPindah();
      Map<String, dynamic> pengampuData = pengampuSnapshot.data()!;
      String tahunajaran = pengampuData['tahunajaran'];
      String tahunAjaranPengampu = tahunajaran.replaceAll('/', '-');

      String uid = firestore.collection('Sekolah').doc().id;

      QuerySnapshot<Map<String, dynamic>> querySnapshotSiswa =
          await firestore
              .collection('Sekolah')
              .doc(idSekolah)
              .collection('tahunajaran')
              .doc(tahunAjaranPengampu)
              .collection('semester')
              .doc(dataFase['namasemester'])
              .collection('kelompokmengaji')
              .doc(dataFase['fase']) // ini nanti diganti otomatis
              .collection('pengampu')
              .doc(dataFase['namapengampu'])
              .collection('tempat')
              .doc(dataFase['tempatmengaji'])
              .collection('daftarsiswa')
              .where('nisn', isEqualTo: nisnSiswa)
              .get();
      if (querySnapshotSiswa.docs.isNotEmpty) {
        Map<String, dynamic> dataSiswa = querySnapshotSiswa.docs.first.data();
        String namasiswa = dataSiswa['namasiswa'];
        String kelassiswa = dataSiswa['kelas'];

        QuerySnapshot<Map<String, dynamic>> getNilainya =
            await firestore
                .collection('Sekolah')
                .doc(idSekolah)
                .collection('tahunajaran')
                .doc(tahunAjaranPengampu)
                .collection('semester')
                .doc(pengampuData['namasemester'])
                .collection('kelompokmengaji')
                .doc(pengampuData['fase'])
                .collection('pengampu')
                .doc(dataFase['namapengampu'])
                .collection('tempat')
                .doc(dataFase['tempatmengaji'])
                .collection('daftarsiswa')
                .doc(nisnSiswa)
                .collection('nilai')
                .get();

        // if (getNilainya.docs.isEmpty) {
        //   Get.snackbar(
        //      "Informasi", "No data available");
        //   return;
        // }

        // ambil semua data doc nilai
        // Map<String, dynamic> allNilaiNya = {};
        // for (var element in getNilainya.docs) {
        //   allNilaiNya[element.id] = element.data();
        // }

        //ambil semua doc id
        Map<String, dynamic> allDocId = {};
        for (var element in getNilainya.docs) {
          allDocId[element.id] = element.data()[element.id];

          // print('allNilaiNya = $allNilaiNya');
          // print('===============================');
          // print('allDocId = $allDocId');

          Map<String, dynamic> allDocNilai = {};
          for (var element in getNilainya.docs) {
            allDocNilai[element.id] = element.data();

            // print("allDocNilai[element.id]['tanggalinput'] = ${allDocNilai[element.id]['tanggalinput']}");
            // print('===============================');
            // print("allDocNilai[element.id]['ummijilidatausurat'] = ${allDocNilai[element.id]['ummijilidatausurat']}");

            //  SIMPAN DATA SISWA PADA TAHUN AJARAN SEKOLAH (PENGAMPU BARU)
            await firestore
                .collection('Sekolah')
                .doc(idSekolah)
                .collection('tahunajaran')
                .doc(tahunAjaranPengampu)
                .collection('semester')
                .doc(pengampuData['namasemester'])
                .collection('kelompokmengaji')
                .doc(pengampuData['fase'])
                .collection('pengampu')
                .doc(pengampuData['namapengampu'])
                .collection('tempat')
                .doc(pengampuData['tempatmengaji'])
                .collection('daftarsiswa')
                .doc(nisnSiswa)
                .set({
                  'namasiswa': namasiswa,
                  'nisn': nisnSiswa,
                  'kelas': kelassiswa,
                  'fase': pengampuData['fase'],
                  'tempatmengaji': pengampuData['tempatmengaji'],
                  'tahunajaran': pengampuData['tahunajaran'],
                  'kelompokmengaji': pengampuData['namapengampu'],
                  'namasemester': pengampuData['namasemester'],
                  'namapengampu': pengampuData['namapengampu'],
                  'idpengampu': pengampuData['idpengampu'],
                  'emailpenginput': emailAdmin,
                  'idpenginput': idUser,
                  'tanggalinput': DateTime.now().toIso8601String(),
                  'idsiswa': nisnSiswa,
                });
            // print('SIMPAN DATA SISWA PADA TAHUN AJARAN SEKOLAH (PENGAMPU BARU)');

            // SIMPAN NILAI DATA SISWA PADA TAHUN AJARAN SEKOLAH (PENGAMPU BARU)
            // Jika nilai pada halaqoh sebelumnya tidak ada maka step ini d lewati
            // ignore: prefer_is_empty
            if (element.id.isNotEmpty || element.id.length != 0) {
              await firestore
                  .collection('Sekolah')
                  .doc(idSekolah)
                  .collection('tahunajaran')
                  .doc(tahunAjaranPengampu)
                  .collection('semester')
                  .doc(pengampuData['namasemester'])
                  .collection('kelompokmengaji')
                  .doc(pengampuData['fase'])
                  .collection('pengampu')
                  .doc(pengampuData['namapengampu'])
                  .collection('tempat')
                  .doc(pengampuData['tempatmengaji'])
                  .collection('daftarsiswa')
                  .doc(nisnSiswa)
                  .collection('nilai')
                  .doc(element.id)
                  .set({
                    'tanggalinput': allDocNilai[element.id]['tanggalinput'],
                    //=========================================
                    "emailpenginput": emailAdmin,
                    "fase": allDocNilai[element.id]['fase'],
                    "idpengampu": allDocNilai[element.id]['idpengampu'],
                    "idsiswa": allDocNilai[element.id]['idsiswa'],
                    "kelas": allDocNilai[element.id]['kelas'],
                    "kelompokmengaji":
                        allDocNilai[element.id]['kelompokmengaji'],
                    "namapengampu": allDocNilai[element.id]['namapengampu'],
                    "namasemester": allDocNilai[element.id]['namasemester'],
                    "namasiswa": allDocNilai[element.id]['namasiswa'],
                    "tahunajaran": allDocNilai[element.id]['tahunajaran'],
                    "tempatmengaji": allDocNilai[element.id]['tempatmengaji'],
                    "hafalansurat": allDocNilai[element.id]['hafalansurat'],
                    "ayathafalansurat":
                        allDocNilai[element.id]['ayathafalansurat'],
                    "ummijilidatausurat":
                        allDocNilai[element.id]['ummijilidatausurat'],
                    "ummihalatauayat":
                        allDocNilai[element.id]['ummihalatauayat'],
                    "materi": allDocNilai[element.id]['materi'],
                    "nilai": allDocNilai[element.id]['nilai'],
                    "keteranganpengampu":
                        allDocNilai[element.id]['keteranganpengampu'],
                    "keteranganorangtua":
                        allDocNilai[element.id]['keteranganorangtua'],
                  });
              // print('SIMPAN NILAI DATA SISWA PADA TAHUN AJARAN SEKOLAH (PENGAMPU BARU)');
            }

            // SIMPAN DATA SISWA PADA (PENGAMPU BARU)
            // await firestore
            //     .collection('Sekolah')
            //     .doc(idSekolah)
            //     .collection('pegawai')
            //     .doc(pengampuData['idpengampu'])
            //     .collection('tahunajarankelompok')
            //     .doc(tahunAjaranPengampu)
            //     .collection('semester')
            //     .doc(pengampuData['namasemester'])
            //     .collection('kelompokmengaji')
            //     .doc(pengampuData['fase'])
            //     .collection('tempat')
            //     .doc(pengampuData['tempatmengaji'])
            //     .collection('daftarsiswa')
            //     .doc(nisnSiswa)
            //     .set({
            //   'namasiswa': namasiswa,
            //   'nisn': nisnSiswa,
            //   'kelas': kelassiswa,
            //   'fase': pengampuData['fase'],
            //   'tempatmengaji': pengampuData['tempatmengaji'],
            //   'tahunajaran': pengampuData['tahunajaran'],
            //   'kelompokmengaji': pengampuData['namapengampu'],
            //   'namasemester': pengampuData['namasemester'],
            //   'namapengampu': pengampuData['namapengampu'],
            //   'idpengampu': pengampuData['idpengampu'],
            //   'emailpenginput': emailAdmin,
            //   'idpenginput': idUser,
            //   'tanggalinput': DateTime.now().toIso8601String(),
            //   'idsiswa': nisnSiswa,
            // });
            // print('SIMPAN DATA SISWA PADA (PENGAMPU BARU)');

            // BUAT TEMPAT di firebase MURID PINDAHAN HALAQOH PADA DATABASE
            await firestore
                .collection('Sekolah')
                .doc(idSekolah)
                .collection('tahunajaran')
                .doc(tahunAjaranPengampu)
                .collection('semester')
                .doc(pengampuData['namasemester'])
                .collection('pindahan')
                // .doc(docIdPindah)
                .doc(uid)
                .set({
                  'namasiswa': namasiswa,
                  'nisn': nisnSiswa,
                  'kelas': kelassiswa,
                  'fase': pengampuData['fase'],
                  'emailpenginput': emailAdmin,
                  'idpenginput': idUser,
                  'tanggalpindah': DateTime.now().toIso8601String(),
                  'halaqohlama': dataFase['namapengampu'],
                  'tempathalaqohlama': dataFase['tempatmengaji'],
                  'halaqohbaru': pengampuData['namapengampu'],
                  'tempathalaqohbaru': pengampuData['tempatmengaji'],
                  'alasanpindah': alasanC.text,
                  'idsiswa': nisnSiswa,
                });

            //HAPUS DATA PADA PENGAMPU LAMA
            // jika ada nilai pada siswa di pengampu lama, maka hapus semua data nilai pada pengampu lama

            DocumentSnapshot<Map<String, dynamic>> docSnapIdSiswa =
                await firestore
                    .collection('Sekolah')
                    .doc(idSekolah)
                    .collection('tahunajaran')
                    .doc(tahunAjaranPengampu)
                    .collection('semester')
                    .doc(pengampuData['namasemester'])
                    .collection('kelompokmengaji')
                    .doc(pengampuData['fase'])
                    .collection('pengampu')
                    .doc(dataFase['namapengampu'])
                    .collection('tempat')
                    .doc(dataFase['tempatmengaji'])
                    .collection('daftarsiswa')
                    .doc(nisnSiswa)
                    .get();

            // ignore: prefer_is_empty
            if (element.id.isNotEmpty || element.id.length != 0) {
              await firestore
                  .collection('Sekolah')
                  .doc(idSekolah)
                  .collection('tahunajaran')
                  .doc(tahunAjaranPengampu)
                  .collection('semester')
                  .doc(pengampuData['namasemester'])
                  .collection('kelompokmengaji')
                  .doc(pengampuData['fase'])
                  .collection('pengampu')
                  .doc(dataFase['namapengampu'])
                  .collection('tempat')
                  .doc(dataFase['tempatmengaji'])
                  .collection('daftarsiswa')
                  .doc(nisnSiswa)
                  .collection('nilai')
                  .get()
                  .then((querySnapshot) {
                    querySnapshot.docs.forEach((doc) async {
                      await firestore
                          .collection('Sekolah')
                          .doc(idSekolah)
                          .collection('tahunajaran')
                          .doc(tahunAjaranPengampu)
                          .collection('semester')
                          .doc(pengampuData['namasemester'])
                          .collection('kelompokmengaji')
                          .doc(pengampuData['fase'])
                          .collection('pengampu')
                          .doc(dataFase['namapengampu'])
                          .collection('tempat')
                          .doc(dataFase['tempatmengaji'])
                          .collection('daftarsiswa')
                          .doc(nisnSiswa)
                          .collection('nilai')
                          .doc(doc.id)
                          .delete();
                    });
                  });
            }

            if (docSnapIdSiswa.exists) {
              //HAPUS DATA PADA PENGAMPU LAMA
              await firestore
                  .collection('Sekolah')
                  .doc(idSekolah)
                  .collection('tahunajaran')
                  .doc(tahunAjaranPengampu)
                  .collection('semester')
                  .doc(pengampuData['namasemester'])
                  .collection('kelompokmengaji')
                  .doc(pengampuData['fase'])
                  .collection('pengampu')
                  .doc(dataFase['namapengampu'])
                  .collection('tempat')
                  .doc(dataFase['tempatmengaji'])
                  .collection('daftarsiswa')
                  .doc(nisnSiswa)
                  .delete();
            }

            //HAPUS DATA DARI DOCUMENT PEGAWAI
            await firestore
                .collection('Sekolah')
                .doc(idSekolah)
                .collection('pegawai')
                .doc(dataFase['idpengampu'])
                .collection('tahunajarankelompok')
                .doc(tahunAjaranPengampu)
                .collection('semester')
                .doc(dataFase['namasemester'])
                .collection('kelompokmengaji')
                .doc(dataFase['fase'])
                .collection('pengampu')
                .doc(dataFase['namapengampu'])
                .collection('tempat')
                .doc(dataFase['tempatmengaji'])
                .collection('daftarsiswa')
                .doc(nisnSiswa)
                .delete();

            //UBAH DATA PADA DOCUMENT SISWA
            await firestore
                .collection('Sekolah')
                .doc(idSekolah)
                .collection('siswa')
                .doc(nisnSiswa)
                .collection('tahunajarankelompok')
                .doc(tahunAjaranPengampu)
                .collection('semester')
                .doc(dataFase['namasemester'])
                .collection('kelompokmengaji')
                .doc(dataFase['fase'])
                .update({
                  "idpengampu": pengampuData['idpengampu'],
                  "kelompokmengaji": pengampuData['namapengampu'],
                  "namapengampu": pengampuData['namapengampu'],
                  "tempatmengaji": pengampuData['tempatmengaji'],
                  "pernahpindah": "iya",
                });

            //DELETED TEMPAT LAMA PADA SISWA
            await firestore
                .collection('Sekolah')
                .doc(idSekolah)
                .collection('siswa')
                .doc(nisnSiswa)
                .collection('tahunajarankelompok')
                .doc(tahunAjaranPengampu)
                .collection('semester')
                .doc(pengampuData['namasemester'])
                .collection('kelompokmengaji')
                .doc(pengampuData['fase'])
                .collection('tempat')
                .doc(dataFase['tempatmengaji'])
                .delete();

            // BUAT TEMPAT BARU PADA SISWA
            await firestore
                .collection('Sekolah')
                .doc(idSekolah)
                .collection('siswa')
                .doc(nisnSiswa)
                .collection('tahunajarankelompok')
                .doc(tahunAjaranPengampu)
                .collection('semester')
                .doc(pengampuData['namasemester'])
                .collection('kelompokmengaji')
                .doc(pengampuData['fase'])
                .collection('tempat')
                .doc(pengampuData['tempatmengaji'])
                .set({
                  'nisn': nisnSiswa,
                  'tempatmengaji': pengampuData['tempatmengaji'],
                  'fase': pengampuData['fase'],
                  'tahunajaran': pengampuData['tahunajaran'],
                  'kelompokmengaji': pengampuData['namapengampu'],
                  'namasemester': pengampuData['namasemester'],
                  'namapengampu': pengampuData['namapengampu'],
                  'idpengampu': pengampuData['idpengampu'],
                  'emailpenginput': emailAdmin,
                  'idpenginput': idUser,
                  'tanggalinput': DateTime.now().toIso8601String(),
                });
          }
        }

        Get.back();
        Get.snackbar('Berhasil', 'berhasil memindahkan siswa');
      }
    }
  }
}

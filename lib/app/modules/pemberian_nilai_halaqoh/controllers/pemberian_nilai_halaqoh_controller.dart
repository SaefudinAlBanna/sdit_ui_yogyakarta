import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PemberianNilaiHalaqohController extends GetxController {
  RxString keteranganHalaqoh = "".obs;

  TextEditingController suratC = TextEditingController();
  TextEditingController ayatHafalC = TextEditingController();
  TextEditingController jldSuratC = TextEditingController();
  TextEditingController halAyatC = TextEditingController();
  TextEditingController materiC = TextEditingController();
  TextEditingController nilaiC = TextEditingController();
  // TextEditingController keteranganGuruC = TextEditingController();

  var data = Get.arguments;

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  String idUser = FirebaseAuth.instance.currentUser!.uid;
  String idSekolah = '20404148';
  String emailAdmin = FirebaseAuth.instance.currentUser!.email!;

  onChangeAlias(String catatan) {
    keteranganHalaqoh.value = catatan;
  }

  Future<String> ambilDataUmi() async {
    String idTahunAjaranNya = data['tahunajaran'];
    String idTahunAjaran = idTahunAjaranNya.replaceAll("/", "-");

    CollectionReference<Map<String, dynamic>> colSemester = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        // .collection('semester')
        // .doc(data['namasemester'])
        .collection('kelompokmengaji')
        .doc(data['fase'])
        .collection('pengampu')
        .doc(data['namapengampu'])
        .collection('tempat')
        .doc(data['tempatmengaji'])
        .collection('daftarsiswa')
        .doc(data['nisn'])
        .collection('semester');

    QuerySnapshot<Map<String, dynamic>> snapSemester = await colSemester.get();
    if (snapSemester.docs.isNotEmpty) {
      Map<String, dynamic> dataSemester = snapSemester.docs.first.data();
      String umi = dataSemester['ummi'];

      return umi;
    }
    throw Exception('UMI data not found');
  }

  Future<void> simpanNilai() async {
    // print("data = $data");
    if (data != null && data.isNotEmpty) {
      String idTahunAjaranNya = data['tahunajaran'];
      String idTahunAjaran = idTahunAjaranNya.replaceAll("/", "-");

      CollectionReference<Map<String, dynamic>> colSemester = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          // .collection('semester')
          // .doc(data['namasemester'])
          .collection('kelompokmengaji')
          .doc(data['fase'])
          .collection('pengampu')
          .doc(data['namapengampu'])
          .collection('tempat')
          .doc(data['tempatmengaji'])
          .collection('daftarsiswa')
          .doc(data['nisn'])
          .collection('semester');

      QuerySnapshot<Map<String, dynamic>> snapSemester =
          await colSemester.get();
      if (snapSemester.docs.isNotEmpty) {
        Map<String, dynamic> dataSemester = snapSemester.docs.first.data();
        String namaSemester = dataSemester['namasemester'];
        String umi = dataSemester['ummi'];

        CollectionReference<Map<String, dynamic>> colNilai = firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('tahunajaran')
            .doc(idTahunAjaran)
            .collection('kelompokmengaji')
            .doc(data['fase'])
            .collection('pengampu')
            .doc(data['namapengampu'])
            .collection('tempat')
            .doc(data['tempatmengaji'])
            .collection('daftarsiswa')
            .doc(data['nisn'])
            .collection('semester')
            .doc(namaSemester)
            .collection('nilai');

        QuerySnapshot<Map<String, dynamic>> snapNilai = await colNilai.get();

        DateTime now = DateTime.now();
        String docIdNilai = DateFormat.yMd().format(now).replaceAll('/', '-');

        //konversi nilai string ke integer
        int nilaiNumerik = int.parse(nilaiC.text);

        //mendapatkan grade huruf
        String grade = getGrade(nilaiNumerik);

        // ignore: prefer_is_empty
        if (snapNilai.docs.length == 0 || snapNilai.docs.isEmpty) {
          //belum pernah input nilai & set nilai
          colNilai.doc(docIdNilai).set({
            "tanggalinput": now.toIso8601String(),
            "emailpenginput": emailAdmin,
            "fase": data['fase'],
            "idpengampu": idUser,
            "idsiswa": data['nisn'],
            "kelas": data['kelas'],
            "kelompokmengaji": data['kelompokmengaji'],
            "namapengampu": data['namapengampu'],
            "namasemester": namaSemester,
            "namasiswa": data['namasiswa'],
            "tahunajaran": data['tahunajaran'],
            "tempatmengaji": data['tempatmengaji'],
            "hafalansurat": suratC.text,
            "ayathafalansurat": ayatHafalC.text,
            "ummijilidatausurat": umi,
            "ummihalatauayat": halAyatC.text,
            "materi": materiC.text,
            "nilai": nilaiC.text,
            "nilaihuruf": grade,
            "keteranganpengampu": keteranganHalaqoh.value,
            "keteranganorangtua": "0",
            "uidnilai": docIdNilai,
          });

          // Get.back();
          Get.snackbar(
            'Informasi',
            'Berhasil input nilai',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.grey[350],
          );
          refresh();
        } else {
          DocumentSnapshot<Map<String, dynamic>> docNilaiToday =
              await colNilai.doc(docIdNilai).get();

          if (docNilaiToday.exists == true) {
            // Get.snackbar('Informasi', 'hari ini ananda sudah input nilai',
            //     snackPosition: SnackPosition.BOTTOM,
            //     backgroundColor: Colors.grey[350]);
            Get.defaultDialog(
              title: 'Informasi',
              content: Text(
                'Hari ini ananda sudah input nilai, Apakah Ananda mau update nilai??',
                style: TextStyle(fontSize: 16),
              ),
              textConfirm: 'OK',
              onConfirm: () {
                refresh();
                Get.snackbar("isi logika", "nilainya harus diupdate");
              },
            );
          } else {
            colNilai.doc(docIdNilai).set({
              "tanggalinput": now.toIso8601String(),
              "emailpenginput": emailAdmin,
              "fase": data['fase'],
              "idpengampu": idUser,
              "idsiswa": data['nisn'],
              "kelas": data['kelas'],
              "kelompokmengaji": data['kelompokmengaji'],
              "namapengampu": data['namapengampu'],
              "namasemester": namaSemester,
              "namasiswa": data['namasiswa'],
              "tahunajaran": data['tahunajaran'],
              "tempatmengaji": data['tempatmengaji'],
              "hafalansurat": suratC.text,
              "ayathafalansurat": ayatHafalC.text,
              "ummijilidatausurat": umi,
              "ummihalatauayat": halAyatC.text,
              "materi": materiC.text,
              "nilai": nilaiC.text,
              "nilaihuruf": grade,
              "keteranganpengampu": keteranganHalaqoh.value,
              "keteranganorangtua": "0",
              "uidnilai": docIdNilai,
            });

            Get.back();

            Get.snackbar(
              'Informasi',
              'Berhasil input nilai',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.grey[350],
            );

            refresh();
          }
        }
      }
    }
  }

  String getGrade(int score) {
    if (score >= 90 && score <= 100) {
      return 'A';
    } else if (score >= 70 && score <= 80) {
      return 'B';
    } else if (score >= 50 && score <= 60) {
      return 'C';
    } else if (score >= 30 && score <= 40) {
      return 'D';
    } else if (score >= 0 && score <= 20) {
      return 'E';
    } else {
      return 'Nilai tidak valid';
    }
  }
}

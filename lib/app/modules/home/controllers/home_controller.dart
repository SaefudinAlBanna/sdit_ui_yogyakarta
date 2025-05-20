import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../pages/home.dart';
import '../pages/marketplace.dart';
import '../pages/profile.dart';

class HomeController extends GetxController {
  RxInt indexWidget = 0.obs;
  RxBool isLoading = false.obs;

  TextEditingController kelasSiswaC = TextEditingController();
  TextEditingController tahunAjaranBaruC = TextEditingController();

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  String idUser = FirebaseAuth.instance.currentUser!.uid;
  String idSekolah = "20404148";
  String emailAdmin = FirebaseAuth.instance.currentUser!.email!;

  void changeIndex(int index) {
    indexWidget.value = index;
  }

  final List<Widget> myWidgets = [
    HomePage(),
    MarketplacePage(),
    ProfilePage(),
  ];

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

    if (listTahunAjaran.elementAt(0)['namatahunajaran'] != tahunAjaranBaruC.text) {
      if (!listTahunAjaran
          .any((element) => element['namatahunajaran'] == tahunAjaranBaruC.text)) {
        //belum input tahun ajaran yang baru, maka bikin tahun ajaran baru
        colTahunAjaran.doc(idTahunAjaran).set({
          'namatahunajaran': tahunAjaranBaruC.text,
          'idpenginput': uid,
          'emailpenginput': emailPenginput,
          'namapenginput': snapDataPenginput.data()?['nama'],
          'tanggalinput': DateTime.now().toString(),
          'idtahunajaran': idTahunAjaran,
        }).then(
          (value) => {
              Get.snackbar('Berhasil', 'Tahun ajaran sudah berhasil dibuat'),
              tahunAjaranBaruC.text = ""
          }
        );
      } else {
        Get.snackbar('Gagal', 'Tahun ajaran sudah ada');
      }
      // Get.back();
    }
    // Get.back();
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
    String idSemester = 'Semester I';  // nanti ini diambil dari database

    List<String> faseList = [];
    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('semester')
        .doc(idSemester)
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
    // String tahunajaranya = await getTahunAjaranTerakhir(); // ambil dari tahun ajaran di collection pegawai
    // String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    List<String> kelasList = [];
    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(idUser)
        .collection('tahunajaran')
        .doc("idTahunAjaran") // tahun ajaran yang d kelas pegawai
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


  Future<List<String>> getDataKelompok() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    String idSemester = 'Semester I';

    List<String> kelasList = [];
    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(idUser)
        .collection('tahunajarankelompok')
        .doc(idTahunAjaran)
        .collection('semester')
        .doc(idSemester)
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

}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class TambahSiswaController extends GetxController {
  RxString jenisKelamin = "".obs;
  RxBool isLoading = false.obs;
  RxBool isLoadingTambahSiswa = false.obs;

  TextEditingController nisnC = TextEditingController();
  TextEditingController namaC = TextEditingController();
  TextEditingController emailC = TextEditingController();
  TextEditingController passAdminC = TextEditingController();

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  String idSekolah = "20404148";

  onChangeJenisKelamin(String nilai) {
    jenisKelamin.value = nilai;
  }

  Future<void> siswaDitambahkan() async {

    if (passAdminC.text.isNotEmpty) {
      isLoadingTambahSiswa.value = true;
      try {
        String emailAdmin = auth.currentUser!.email!;

        // (jangan dihapus)
        // ignore: unused_local_variable
        UserCredential userCredentialAdmin  = await auth.signInWithEmailAndPassword(
          email: emailAdmin,
          password: passAdminC.text,
        );

        UserCredential siswaCredential =
            await auth.createUserWithEmailAndPassword(
          email: emailC.text,
          password: 'sditui',
        );
        // print(siswaCredential);

        if (siswaCredential.user != null) {
          String uid = siswaCredential.user!.uid;

          await firestore
              .collection("Sekolah")
              .doc(idSekolah)
              .collection('siswa')
              .doc(nisnC.text)
              .set({
            "nisn": nisnC.text,
            "nama": namaC.text,
            "email": emailC.text,
            "jeniskelamin" : jenisKelamin.value,
            "uid": uid,
            "tanggalinput": DateTime.now().toIso8601String(),
            "emailpenginput" : emailAdmin,
            "agama": "Islam",
            "tempatLahir": "",
            "tanggalLahir": "",
            "alamat": "",
            "namaAyah": "",
            "namaIbu": "",
            "noHpOrangTua": "",
            "alamatOrangTua": "",
            "pekerjaanAyah": "",
            "pekerjaanIbu": "",
            "pendidikanAyah": "",
            "pendidikanIbu": "",
            "noHpWali": "",
            "alamatWali": "",
            "pekerjaanWali": "",
            "pendidikanWali": "",
            "status": "baru",
            // "biayaSpp": biayaSppController.text,
            // "biayaUangPangkal": biayaUangPangkalController.text,
          });

          await siswaCredential.user!.sendEmailVerification();

          await auth.signOut();

          //disini login ulang admin penginput (jangan dihapus)
          // ignore: unused_local_variable
          UserCredential userCredentialAdmin  = await auth.signInWithEmailAndPassword(
          email: emailAdmin,
          password: passAdminC.text,
        );

          Get.back(); // tutup dialog
          Get.back(); // back to home

          Get.snackbar(
              snackPosition: SnackPosition.BOTTOM,
              'Berhasil',
              'siswa berhasil ditambahkan');
        }
        isLoadingTambahSiswa.value = false;
      } on FirebaseAuthException catch (e) {
        isLoadingTambahSiswa.value = false;
        if (e.code == 'weak-password') {
          Get.snackbar(
              snackPosition: SnackPosition.BOTTOM,
              'Terjadi Kesalahan',
              'Password terlalu singkat');
        } else if (e.code == 'email-already-in-use') {
          Get.snackbar(
              snackPosition: SnackPosition.BOTTOM,
              'Terjadi Kesalahan',
              'email siswa sudah terdaftar');
        } else if (e.code == 'invalid-credential') {
          Get.snackbar(
              snackPosition: SnackPosition.BOTTOM,
              'Terjadi Kesalahan',
              'password salah');
        } else {
          Get.snackbar(
              snackPosition: SnackPosition.BOTTOM, 'Terjadi Kesalahan', e.code);
        }
      } catch (e) {
        isLoadingTambahSiswa.value = false;
        Get.snackbar(
            snackPosition: SnackPosition.BOTTOM,
            'Terjadi Kesalahan',
            'Tidak dapat menambahkan siswa, harap dicoba lagi');
      }
    } else {
      isLoading.value = false;
      Get.snackbar(
          snackPosition: SnackPosition.BOTTOM,
          'Error',
          'Password Admin wajib diisi');
    }
  }

  Future<void> tambahSiswa() async {
    if (isLoading.value = true) {
          Get.defaultDialog(
            title: 'Verifikasi Email',
            content: Column(
              children: [
                TextFormField(
                  controller: passAdminC,
                  decoration: const InputDecoration(
                    labelText: 'Password Admin'),
                ),
              ],
            ),
            actions: [
              OutlinedButton(
                onPressed: () {
                  isLoading.value = false;
                  Get.back();
                },
                child: Text('CANCEL'),
              ),
              Obx(
                () => ElevatedButton(
                  onPressed: () async {
                    if (isLoadingTambahSiswa.isFalse) {
                      await siswaDitambahkan();
                    }
                    isLoading.value = false;
                  },
                  child: Text(isLoadingTambahSiswa.isFalse
                      ? 'Tambah Siswa'
                      : 'LOADING...'),
                ),
              ),
            ],
          );
    } else {
      Get.snackbar(
        'Gagal',
        'Semua data harus diisi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      } 
    }

}

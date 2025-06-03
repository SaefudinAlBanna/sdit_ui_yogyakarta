import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';

class LoginController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isLogin = false.obs;
  
  TextEditingController emailC = TextEditingController();
  TextEditingController passC = TextEditingController();

  FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> login() async {
    if (emailC.text.isNotEmpty && passC.text.isNotEmpty) {
      isLoading.value = true;
      try {
        UserCredential userCredential = await auth.signInWithEmailAndPassword(
          email: emailC.text,
          password: passC.text,
        );

        if (userCredential.user != null) {
          if (userCredential.user != null) {
            if (userCredential.user!.emailVerified == true) {
              isLoading.value = false;
              if (passC.text == "sditui") {
                Get.offAllNamed(Routes.NEW_PASSWORD);
              } else {
                Get.offAllNamed(Routes.HOME);
              }
            } else {
              
              Get.defaultDialog(
                title: 'Belum verifikasi',
                middleText: 'Silahkan verifikasi terlebih dahulu',
                actions: [
                  OutlinedButton(
                    onPressed: () {
                      isLoading.value = false;
                      Get.back();
                    },
                    child: Text('CANCEL'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await userCredential.user!.sendEmailVerification();
                        Get.back();
                        Get.snackbar('Berhasil',
                            'email verifikasi sudah berhasil terkirim');
                            isLoading.value = false;
                      } catch (e) {
                            isLoading.value = false;
                        Get.snackbar(
                            'Terjadi Kesalahan', 'Silahkan dicoba lagi nanti');
                      }
                    },
                    child: Text('Kirim Ulang Verifikasi'),
                  ),
                ],
              );
            }
          }
        } else {
          Get.snackbar('Peringatan', 'email belum terfverifikasi');
        }

        // print(userCredential);
        isLoading.value = false;
      } on FirebaseAuthException catch (e) {
        isLoading.value = false;
        if (e.code == 'invalid-credential') {
          Get.snackbar("Peringatan", 'Periksa kembali, apakah email, password sudah benar?? dan apakah akun email sudah terdaftar',
              snackPosition: SnackPosition.BOTTOM,
              snackStyle: SnackStyle.FLOATING,
              // borderColor: Colors.grey
              backgroundColor: Colors.grey);
        } else {
          Get.snackbar(
              snackPosition: SnackPosition.BOTTOM, 'Terjadi Kesalahan', e.code);
        }
      } catch (e) {
        isLoading.value = false;
        Get.snackbar("Terjadi kesalahan", "Tidak dapat login",
            snackPosition: SnackPosition.BOTTOM,
            snackStyle: SnackStyle.FLOATING,
            // borderColor: Colors.grey
            backgroundColor: Colors.grey);
      }
    } else {
      Get.snackbar("Peringatan", "Email & Password Wajib diisi",
          snackPosition: SnackPosition.BOTTOM,
          snackStyle: SnackStyle.FLOATING,
          // borderColor: Colors.grey
          backgroundColor: Colors.grey);
    }
  }

  Future<String> loginUser() async {
    String res = " Some error ocured";
    if (emailC.text.isNotEmpty && passC.text.isNotEmpty) {
      try {
        UserCredential userCredential = await auth.signInWithEmailAndPassword(
            email: emailC.text, password: passC.text);

        if (userCredential.user != null) {
          if (userCredential.user != null) {
            if (userCredential.user!.emailVerified == true) {
              if (passC.text == "password" || passC.text == "Password") {
                Get.offAllNamed(Routes.NEW_PASSWORD);
              } else {
                res = "Succes";
                Get.offAllNamed(Routes.HOME);
              }
            } else {
              Get.defaultDialog(
                title: 'Belum verifikasi',
                middleText: 'Silahkan verifikasi terlebih dahulu',
                actions: [
                  OutlinedButton(
                    onPressed: () => Get.back(),
                    child: Text('CANCEL'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await userCredential.user!.sendEmailVerification();
                        Get.back();
                        Get.snackbar('Berhasil',
                            'email verifikasi sudah berhasil terkirim');
                      } catch (e) {
                        Get.snackbar(
                            'Terjadi Kesalahan', 'Silahkan dicoba lagi nanti');
                      }
                    },
                    child: Text('Kirim Ulang Verifikasi'),
                  ),
                ],
              );
            }
          }
        } else {
          res = 'email belum terfverifikasi';
        }
      } catch (e) {
        return e.toString();
      }
    }
    return res;
  }

  void loginuser() async {
    String res = await LoginController().loginUser();

    if (res == "Succes") {
      Get.offAllNamed(Routes.HOME);
    } else {
      Get.snackbar(
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.grey,
          'Peringatan',
          res);
    }
  }
}

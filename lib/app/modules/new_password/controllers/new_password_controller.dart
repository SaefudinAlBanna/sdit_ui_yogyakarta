import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';

class NewPasswordController extends GetxController {
  TextEditingController newpassC = TextEditingController();

  FirebaseAuth auth = FirebaseAuth.instance;

  void changePassword() async {
    if (newpassC.text.isNotEmpty) {
      if (newpassC.text != "password") {
        try {
          // String email = auth.currentUser!.email!;

          await auth.currentUser!.updatePassword(newpassC.text);
          Get.snackbar('Berhasil', 'Silahkan login ulang');
          Get.offAllNamed(Routes.LOGIN);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'weak-password') {
            Get.snackbar("Peringatan", "minimal password 6 karakter",
                snackPosition: SnackPosition.BOTTOM,
                snackStyle: SnackStyle.FLOATING);
          }
        } catch (e) {
        Get.snackbar('Peringatan', 'password baru tidak bisa dibuat, hubungi admin');
        }
      } else {
        Get.snackbar('Peringatan', 'password wajib diubah');
      }
    } else {
      Get.snackbar('Peringatan', 'Password baru wajib diisi');
    }
  }
}

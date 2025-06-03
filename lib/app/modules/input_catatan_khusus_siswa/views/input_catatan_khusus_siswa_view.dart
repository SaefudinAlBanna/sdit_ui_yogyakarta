import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/input_catatan_khusus_siswa_controller.dart';

class InputCatatanKhususSiswaView
    extends GetView<InputCatatanKhususSiswaController> {
  InputCatatanKhususSiswaView({super.key});

  final dataArgumen = Get.arguments;

  @override
  Widget build(BuildContext context) {
    print("dataArgumen =$dataArgumen");
    return Scaffold(
      appBar: AppBar(
        title: Text('${dataArgumen['namasiswa']} ${dataArgumen['namakelas']}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ada apa hari ini?', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: controller.judulC,
              decoration: InputDecoration(
                hintText: 'Judul info',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller.inputC,
              decoration: InputDecoration(
                hintText: 'Tulis Info...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 10, // Untuk membuat input multiline seperti status Facebook
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller.tindakanC,
              decoration: InputDecoration(
                hintText: 'Tindakan yang sudah dilakukan guru BK',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // ignore: unnecessary_null_comparison
                if(controller.judulC.text == null || controller.judulC.text == '' || controller.judulC.text.isEmpty) {
                  Get.snackbar(
                    'Error',
                    'Judul masih kosong',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                    );
                }
                // ignore: unnecessary_null_comparison
                else if(controller.inputC.text == null || controller.inputC.text == '' || controller.inputC.text.isEmpty) {
                  Get.snackbar(
                    'Error',
                    'Info masih kosong',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                    );
                } 
                // ignore: unnecessary_null_comparison
                else if(controller.tindakanC.text == null || controller.tindakanC.text == '' || controller.tindakanC.text.isEmpty) {
                  Get.snackbar(
                    'Error',
                    'Tindakan masih kosong',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                    );
                } else {
                  controller.simpanCatatanSiswa();
                  // controller.test();
                }
               
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

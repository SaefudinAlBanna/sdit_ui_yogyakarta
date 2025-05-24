import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../controllers/daftar_halaqoh_perfase_controller.dart';

class DaftarHalaqohPerfaseView extends GetView<DaftarHalaqohPerfaseController> {
   DaftarHalaqohPerfaseView({super.key});

  final data = Get.arguments;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: controller.getFaseHalaqoh(),
        builder: (context, snapshotfase) {
          if (snapshotfase.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshotfase.hasData) {
            return Scaffold(
                appBar: AppBar(
                  title: Text('Halaqoh $data'),
                  centerTitle: true,
                  actions: [
                    IconButton(onPressed: (){
                      Get.toNamed(Routes.DAFTAR_SISWA_PINDAH_HALAQOH);
                    }, icon: Icon(Icons.view_list)),
                  ],
                ),
                body: SafeArea(
                    child: ListView.builder(
                  itemCount: snapshotfase.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshotfase.data!.docs[index];
                    return ListTile(
                      onTap: () => Get.toNamed(Routes.DAFTAR_HALAQOH, arguments: doc),
                      leading: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(50),
                          image: DecorationImage(
                              image: NetworkImage(
                                  "https://ui-avatars.com/api/?name=${doc['namapengampu']}")),
                        ),
                      ),
                      title: Text(doc['namapengampu'] ?? 'No Data'),
                      subtitle: Text(doc['tempatmengaji'] ?? 'No Data'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            tooltip: 'Lihat',
                            icon: const Icon(Icons.arrow_circle_right_outlined),
                            onPressed: () {
                              Get.toNamed(Routes.DAFTAR_HALAQOH, arguments: doc);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                )));
          } else {
            return Center(
              child: Text('Terjadi kesalahan, Periksa koneksi internet'),
            );
          }
        });
  }
}

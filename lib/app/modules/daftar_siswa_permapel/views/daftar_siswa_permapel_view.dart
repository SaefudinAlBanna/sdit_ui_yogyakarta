import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/daftar_siswa_permapel_controller.dart';

class DaftarSiswaPermapelView extends GetView<DaftarSiswaPermapelController> {
  DaftarSiswaPermapelView({super.key});

  final dataArgumen = Get.arguments;

  @override
  Widget build(BuildContext context) {
    print("dataArgumen = $dataArgumen");
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Siswa $dataArgumen'),
        centerTitle: true,
      ),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: controller.getDataSiswa(),
        builder: (context, snapsiswa) {
          if (snapsiswa.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapsiswa.data == null || snapsiswa.data!.docs.isEmpty) {
            print("snapsiswa.lenght = ${snapsiswa.data!.docs.length}");
            return Center(child: Text("Siswa tidak ada"));
          }
          if (snapsiswa.hasData) {
            return ListView(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapsiswa.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapsiswa.data!.docs[index].data();
                    return InkWell(
                      onTap: (){},
                      child: Container(
                        margin: EdgeInsets.fromLTRB(15, 0, 15, 8),
                        padding: EdgeInsets.fromLTRB(15, 3, 15, 8),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // SizedBox(height: 10),
                            Text(data['namasiswa']),
                          ]
                        ),
                      ),
                    );
                  },
                )
              ],
            );
          }  else {
            return Center(
              child: Text("tidak dapat memuat data, periksa koneksi internet"),
            );
          }
        },
      ),
    );
  }
}

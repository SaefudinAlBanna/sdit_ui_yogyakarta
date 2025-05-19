import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../controllers/daftar_halaqoh_pengampu_controller.dart';

class DaftarHalaqohPengampuView
    extends GetView<DaftarHalaqohPengampuController> {
   DaftarHalaqohPengampuView({super.key});

  final data = Get.arguments;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: controller.getDaftarHalaqohPengampu(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            return Scaffold(
                appBar: AppBar(
                  title: Text(data),
                  centerTitle: true,
                ),
                body: ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = (snapshot.data as QuerySnapshot).docs[index];
                    return ListTile(
                      leading: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(50),
                          image: DecorationImage(
                              image: NetworkImage(
                                  "https://ui-avatars.com/api/?name=${doc['namasiswa']}")),
                        ),
                      ),
                      title: Text(doc['namasiswa'] ?? 'No Data'),
                      subtitle: Text(doc['kelas'] ?? 'No Data'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          GestureDetector(
                            onTap: () {
                              String getNama =
                                  snapshot.data!.docs[index].data()['nisn'];
                              Get.toNamed(Routes.DETAIL_SISWA,
                                  arguments: getNama);
                            },
                            child: SizedBox(
                                height: 40,
                                width: 40,
                                // color: Colors.amber,
                                child: Icon(Icons.info_outlined)),
                          ),


                          GestureDetector(
                            onTap:() {
                              var dataNya = snapshot.data!.docs[index].data();
                                Get.toNamed(Routes.PEMBERIAN_NILAI_HALAQOH,
                                    // arguments: snapshot.data!.docs[index].data()['namasiswa']);
                                    arguments: dataNya);
                                    // print('datamua = ${snapshot.data!.docs[index].data()}');
                            } ,
                            child: SizedBox(
                                height: 40,
                                width: 40,
                                // color: Colors.amber,
                                child: Icon(Icons.add_box_outlined)),
                          
                          ),


                          GestureDetector(
                            onTap:() {
                              Map<String, dynamic> dataNya = snapshot.data!.docs[index].data();
                              Get.toNamed(Routes.DAFTAR_NILAI, arguments: dataNya);
                            },
                            child: SizedBox(
                                height: 40,
                                width: 40,
                                // color: Colors.amber,
                                child: Icon(Icons.book)),
                          
                          ),

                          // SizedBox(
                          //   height: 40,
                          //   width: 40,
                          //   child: Checkbox(
                          //     value: false,
                          //     onChanged: (bool? value) {
                          //       // Handle checkbox state change here
                          //     },
                          //   ),
                          // )
                        ],
                      ),
                    );
                  },
                ));
           } else {
            return Center(
              child: Text('Terjadi kesalahan, Periksa koneksi internet'),
            );
          }
        });
  }
}

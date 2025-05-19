import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/pemberian_kelas_siswa_controller.dart';

class PemberianKelasSiswaView extends GetView<PemberianKelasSiswaController> {
  PemberianKelasSiswaView({super.key});

  final dataKelas = Get.arguments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Kelas Siswa'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Tahun Ajaran : '),
                    SizedBox(height: 20),
                    FutureBuilder<String>(
                        future: controller.getTahunAjaranTerakhir(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text('Error');
                          } else {
                            return Text(
                              snapshot.data ?? 'No Data',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            );
                          }
                        }),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  'Kelas : $dataKelas',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    future: controller.getDataWali(),
                    // future: null,
                    builder: (context, snapwalikelas) {
                      var datakelasnya = snapwalikelas.data?.docs;
                      if (snapwalikelas.connectionState ==
                          ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapwalikelas.hasData) {
                        if (datakelasnya != null &&
                            datakelasnya.any((doc) =>
                                doc['namakelas'].toString() ==
                                dataKelas.toString())) {
                          // tampilkan data walikelas
                          final waliKelasDoc = datakelasnya.firstWhere(
                              (doc) =>
                                  doc['namakelas'].toString() ==
                                  dataKelas.toString(),
                              orElse: () => throw Exception(
                                  'No matching document found'));
                          // print('waliKelasDoc = $waliKelasDoc');
                          return Text('wali kelas : ${waliKelasDoc['walikelas'] as String? ?? 'No Wali Kelas'}');
                        } 
                      }
                      // return SizedBox.shrink(); // Default return statement
                      return DropdownSearch<String>(
                            decoratorProps: DropDownDecoratorProps(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                filled: null,
                                prefixText: 'Wali kelas : ',
                              ),
                            ),
                            // selectedItem: controller.kelasSiswaC.text,
                            selectedItem: controller.idPegawaiC.text,
                            items: (f, cs) => controller.getDataWaliKelasBaru(),
                            onChanged: (String? value) {
                              controller.waliKelasSiswaC.text = value!;
                              controller.idPegawaiC.text = value;
                            },
                            popupProps: PopupProps.menu(
                                // disabledItemFn: (item) => item == '1A',
                                fit: FlexFit.tight),
                          ); // Default return statement
                    }),

                // ElevatedButton(
                //     onPressed: () {
                //       controller.test();
                //       // print('waliKelasDoc = $waliKelasDoc');
                //     },
                //     child: Text('test')),

              ],
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: controller.tampilkanSiswa,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.active) {
                    final List<DocumentSnapshot<Map<String, dynamic>>> data =
                        snapshot.data!.docs;
                    // ignore: prefer_is_empty
                    if (data.length == 0 || data.isEmpty) {
                      return Center(
                        child: Text('Semua siswa sudah punya kelas'),
                      );
                    } else {
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          String namaSiswa =
                              data[index].data()?['nama'] ?? 'No Name';
                          String nisnSiswa =
                              data[index].data()?['nisn'] ?? 'No NISN';
                          return ListTile(
                            title: Text(namaSiswa),
                            subtitle: Text(nisnSiswa),
                            trailing: IconButton(
                              onPressed: () {
                                // if (controller.waliKelasSiswaC.text.isEmpty) {
                                //   Get.snackbar('Peringatan',
                                //       'Wali kelas tidak boleh kosong');
                                // } else if (controller
                                //     .argumentKelas.isEmpty) {
                                //   Get.snackbar(
                                //       'Peringatan', 'kelas tidak boleh kosong');
                                // }
                                // controller.tambahkanKelasSiswa(
                                //     namaSiswa, nisnSiswa);
                                
                                controller.simpankelasSiswa(namaSiswa, nisnSiswa);
                              },
                              icon: Icon(Icons.save_outlined),
                            ),
                          );
                        },
                      );
                    }
                  }
                  return Center(
                    child: Text('No data available'),
                  );
                }),
          ),
        ],
      ),
      // ],
    );
  }
}

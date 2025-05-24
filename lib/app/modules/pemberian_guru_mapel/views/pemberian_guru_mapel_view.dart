import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/pemberian_guru_mapel_controller.dart';

class PemberianGuruMapelView extends GetView<PemberianGuruMapelController> {
  PemberianGuruMapelView({super.key});

  final dataKelas = Get.arguments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(130),
        child: AppBar(
          backgroundColor: Colors.indigo,
          title: Text('Pemberian Guru Mapel $dataKelas'),
          centerTitle: true,
          flexibleSpace: Padding(
            padding: const EdgeInsets.fromLTRB(30, 50, 20, 5),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: DropdownSearch<String>(
                decoratorProps: DropDownDecoratorProps(
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide(color: Colors.white, width: 1),
                    ),
                    filled: true,
                    prefixText: 'Guru Mapel : ',
                    // labelText: 'Guru Mapel',
                    hintText: 'Guru Mapel',
                    labelStyle: TextStyle(fontSize: 15),
                    hintStyle: TextStyle(fontSize: 15, color: Colors.grey),

                    // prefixStyle: TextStyle(fontSize: 15),
                    // suffixStyle: TextStyle(fontSize: 15),
                    // suffixText: 'Saya',
                    // suffixStyle: TextStyle(fontSize: 15),
                    suffixIcon: Icon(Icons.person),
                    // suffixIconColor: Colors.blue,
                    // suffixIconSize: 20,
                    // suffixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                    // suffixIcon: Icon(Icons.person),
                    // suffixIconColor: Colors.blue,
                    // suffixIconSize: 20,
                    // suffixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                    // suffixIcon: Icon(Icons.person),
                    // suffixIconColor: Colors.blue,
                  ),
                ),
                // selectedItem: controller.kelasSiswaC.text,
                selectedItem: controller.guruMapelC.text,
                items: (f, cs) => controller.getDataGuruMapel(),
                onChanged: (String? value) {
                  controller.guruMapelC.text = value!;
                },
                popupProps: PopupProps.menu(
                  // disabledItemFn: (item) => item == '1A',
                  fit: FlexFit.tight,
                ),
              ),
            ),
          ), // Default return statement
          // },
          // ),
        ),
      ),

      body: Column(
        children: [
          FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
            future: controller.tampilkanMapel(),
            builder: (context, snapTampilMapel) {
              return ListView.builder(
                shrinkWrap: true,
                itemCount: snapTampilMapel.data?.docs.length ?? 0,
                itemBuilder: (context, index) {
                  if (snapTampilMapel.connectionState ==
                      ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapTampilMapel.hasData) {
                    var data = snapTampilMapel.data!.docs[index].data();
                    // return ListTile(
                    //   onTap: () {
                    //     print("yang ke ${index + 1}");
                    //   },
                    //   title: Text(data['namamatapelajaran']),
                    //   subtitle: Text(dataKelas),
                    // );

                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Material(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(15),
                        child: InkWell(
                          onTap: () {
                            if (controller.guruMapelC.text.isEmpty) {
                              Get.snackbar(
                                "Error",
                                "Guru Mapel tidak boleh kosong",
                              );
                            } else {
                              controller.simpanMapel(data['namamatapelajaran']);
                              controller.tampilkan();
                            }
                          },
                          child: Container(
                            margin: EdgeInsets.fromLTRB(20, 10, 10, 0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['namamatapelajaran']),
                                SizedBox(height: 3),
                                Text(dataKelas),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  // Add a default return for other cases
                  return Text("Tidak bisa memuat data, silahkan ulangi lagi");
                },
              );
            },
          ),
          // Divider(height: 3),
          Container(height: 2, color: Colors.grey),
          // ElevatedButton(onPressed: ()=>controller.refreshTampilan(), child: Text("test")),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: controller.tampilkan(),
              builder: (context, snapshotTampil) {
                if (snapshotTampil.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                // ignore: prefer_is_empty
                if (snapshotTampil.data == null ||
                    snapshotTampil.data?.docs.length == 0) {
                  return Center(child: Text('belum ada data'));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshotTampil.data!.docs.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> data =
                        snapshotTampil.data!.docs[index].data()
                            as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['namamatapelajaran']),
                      subtitle: Text("subtitle mapel"),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/jurnal_ajar_harian_controller.dart';

class JurnalAjarHarianView extends GetView<JurnalAjarHarianController> {
  JurnalAjarHarianView({super.key});

  final dataArgument = Get.arguments;

  @override
  Widget build(BuildContext context) {
    // print("dataArgument = $dataArgument");
    return Scaffold(
      appBar: AppBar(
        // title: const Text('JurnalAjarHarianView'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          Column(
            children: [
              FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                future: controller.tampilkanJamPelajaran(),
                builder: (context, snapPilihJurnal) {
                  return ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: snapPilihJurnal.data?.docs.length ?? 0,
                    itemBuilder: (context, index) {
                      if (snapPilihJurnal.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapPilihJurnal.hasData) {
                        var data = snapPilihJurnal.data!.docs[index].data();
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
                                print(
                                  "data['jampelajaran'] = ${data['jampelajaran']}",
                                );
                                Get.bottomSheet(
                                  Container(
                                    height: 400,
                                    color: Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 10,
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[50],
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              data['jampelajaran'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),

                                          DropdownSearch<String>(
                                            decoratorProps:
                                                DropDownDecoratorProps(
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    filled: true,
                                                    prefixText: 'kelas : ',
                                                  ),
                                                ),
                                            selectedItem:
                                                controller.kelasSiswaC.text,
                                            items:
                                                (f, cs) =>
                                                    controller.getDataKelas(),
                                            onChanged: (String? value) {
                                              controller.kelasSiswaC.text =
                                                  value!;
                                            },
                                            popupProps: PopupProps.menu(
                                              // disabledItemFn: (item) => item == '1A',
                                              fit: FlexFit.tight,
                                            ),
                                          ),
                                          SizedBox(height: 15),

                                          DropdownSearch<String>(
                                            decoratorProps:
                                                DropDownDecoratorProps(
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    filled: true,
                                                    prefixText: 'mapel : ',
                                                  ),
                                                ),
                                            selectedItem:
                                                controller.mapelC.text,
                                            items:
                                                (f, cs) =>
                                                    controller.getDataMapel(),
                                            onChanged: (String? value) {
                                              controller.mapelC.text = value!;
                                            },
                                            popupProps: PopupProps.menu(
                                              // disabledItemFn: (item) => item == '1A',
                                              fit: FlexFit.tight,
                                            ),
                                          ),
                                          SizedBox(height: 15),

                                          TextField(
                                            controller:
                                                controller.materimapelC,
                                            decoration: InputDecoration(
                                              labelText: 'Materi Pelajaran',
                                              labelStyle: TextStyle(
                                                fontSize: 12,
                                              ),
                                              border: OutlineInputBorder(),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 15),

                                          TextField(
                                            controller:
                                                controller.catatanjurnalC,
                                            decoration: InputDecoration(
                                              labelText: 'Catatan',
                                              labelStyle: TextStyle(
                                                fontSize: 12,
                                              ),
                                              border: OutlineInputBorder(),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 15),

                                          ElevatedButton(
                                            onPressed: () {
                                              if (controller.kelasSiswaC.text == null ||
                                                  controller
                                                      .kelasSiswaC
                                                      .text
                                                      .isEmpty) {
                                                Get.snackbar(
                                                  "Error",
                                                  "Kelas masih kosong",
                                                );
                                              } else if (controller
                                                          .mapelC
                                                          .text == null ||
                                                  controller
                                                      .mapelC
                                                      .text
                                                      .isEmpty) {
                                                Get.snackbar(
                                                  "Error",
                                                  "Mapel masih kosong",
                                                );
                                              } else if (controller
                                                          .materimapelC
                                                          .text ==
                                                      null ||
                                                  controller
                                                      .materimapelC
                                                      .text
                                                      .isEmpty) {
                                                Get.snackbar(
                                                  "Error",
                                                  "Materi Mapel masih kosong",
                                                );
                                              } else {
                                                controller.simpanDataJurnal(
                                                  data['jampelajaran'],
                                                );
                                              }
                                            },
                                            child: Text("Simpan"),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: EdgeInsets.fromLTRB(20, 10, 10, 0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(data['jampelajaran']),
                              ),
                            ),
                          ),
                        );
                      }
                      // Add a default return for other cases
                      return Text(
                        "Tidak bisa memuat data, silahkan ulangi lagi",
                      );
                    },
                  );
                },
              ),
              // Divider(height: 3),
              Container(height: 2, color: Colors.grey),
              // ElevatedButton(onPressed: ()=>controller.refreshTampilan(), child: Text("test")),
              
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: controller.tampilkanjurnal(),
                // stream: null,
                builder: (context, snapshotTampil) {
                  if (snapshotTampil.connectionState ==
                      ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  // ignore: prefer_is_empty
                  if (snapshotTampil.data == null ||
                      snapshotTampil.data?.docs.length == 0) {
                    return Center(child: Text('belum ada data'));
                  }
                  if (snapshotTampil.hasData) {
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: snapshotTampil.data!.docs.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> data =
                            snapshotTampil.data!.docs[index].data()
                                as Map<String, dynamic>;
                        // return ListTile(
                        //   title: Text(data['namamapel']),
                        //   subtitle: Text(data['jampelajaran']),
                        // );
                        return Container(
                          margin: EdgeInsets.fromLTRB(20, 10, 10, 0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: [
                              Text(data['uidtanggal']),
                              Text(data['jampelajaran']),
                              Text(data['namamapel']),
                              Text(data['materipelajaran']),
                              Text(data['catatanjurnal']),
                            ],
                          ),
                        );
                      },
                    );
                  }
                  // Default return to satisfy non-nullable return type
                  return SizedBox.shrink();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

//       ListView(
//         children: [
//           SafeArea(
//             child: Stack(
//               fit: StackFit.passthrough,
//               children: [
//                 Container(
//                   height: 150,
//                   width: Get.width,
//                   decoration: BoxDecoration(
//                     color: Colors.indigo[400],
//                     // image: DecorationImage(
//                     //   image: AssetImage("assets/images/profile.png"),
//                     // ),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.only(top: 15),
//                     child: Text(
//                       "Jurnal Kelas Harian",
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),

//                 Container(
//                   margin: EdgeInsets.only(top: 50),
//                   // width: Get.width,
//                   child: Column(
//                     children: [
//                       Column(
//                         children: [
//                           Container(
//                             padding: EdgeInsets.symmetric(
//                               horizontal: 15,
//                               vertical: 10,
//                             ),
//                             margin: EdgeInsets.symmetric(horizontal: 25),
//                             // height: 140,
//                             decoration: BoxDecoration(
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.grey.withValues(alpha: 0.5),
//                                   // spreadRadius: 1,
//                                   blurRadius: 3,
//                                   offset: Offset(2, 2),
//                                 ),
//                               ],
//                               color: Colors.grey.shade50,
//                               // borderRadius: BorderRadius.only(
//                               //   topLeft: Radius.circular(20),
//                               //   topRight: Radius.circular(20),
//                               // ),
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             child: Column(
//                               children: [
//                                 FieldJurnal(
//                                   controller: controller,
//                                   controllerNya: controller.ke1C,
//                                   label: "07.30-08.00",
//                                   color: Colors.grey,
//                                   jam: "07.30-08.00",
//                                 ),
//                                 FieldJurnal(
//                                   controller: controller,
//                                   controllerNya: controller.ke2C,
//                                   label: "08.00-08.30",
//                                   color: Colors.grey,
//                                   jam: "08.00-08.30",
//                                 ),
//                                 FieldJurnal(
//                                   controller: controller,
//                                   controllerNya: controller.ke3C,
//                                   label: "08.30-09.00",
//                                   color: Colors.green,
//                                   jam: "08.30-09.00",
//                                 ),
//                                 FieldJurnal(
//                                   controller: controller,
//                                   controllerNya: controller.ke4C,
//                                   label: "09.00-09.30",
//                                   color: Colors.green,
//                                   jam: "09.00-09.30",
//                                 ),

//                                 //istirahat makan snack
//                                 Row(
//                                   children: [
//                                     Container(
//                                       margin: EdgeInsets.only(top: 10),
//                                       padding: EdgeInsets.symmetric(
//                                         horizontal: 5,
//                                       ),
//                                       height: 45,
//                                       decoration: BoxDecoration(
//                                         color: Colors.blue,
//                                         borderRadius: BorderRadius.circular(10),
//                                       ),
//                                       child: Center(
//                                         child: Text(
//                                           "09.30-09.50",
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.w600,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                     SizedBox(width: 5),
//                                     Expanded(
//                                       child: Container(
//                                         margin: EdgeInsets.only(top: 10),
//                                         padding: EdgeInsets.symmetric(
//                                           horizontal: 5,
//                                         ),
//                                         // width: Get.width,
//                                         height: 45,
//                                         decoration: BoxDecoration(
//                                           color: Colors.blue,
//                                           borderRadius: BorderRadius.circular(
//                                             10,
//                                           ),
//                                         ),
//                                         child: Center(
//                                           child: Text(
//                                             "Istirahat I (Makan Snack)",
//                                             // style: TextStyle(
//                                             //   fontWeight: FontWeight.w600,
//                                             // ),
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),

//                                 FieldJurnal(
//                                   controller: controller,
//                                   controllerNya: controller.ke5C,
//                                   label: "09.50-10.20",
//                                   color: Colors.brown,
//                                   jam: "09.50-10.20",
//                                 ),
//                                 FieldJurnal(
//                                   controller: controller,
//                                   controllerNya: controller.ke6C,
//                                   label: "11.20-11.50",
//                                   color: Colors.brown,
//                                   jam: "11.20-11.50",
//                                 ),

//                                 //Istirahat II (Sholat Dzuhur & Makan siang)
//                                 Row(
//                                   children: [
//                                     Container(
//                                       margin: EdgeInsets.only(top: 10),
//                                       padding: EdgeInsets.symmetric(
//                                         horizontal: 5,
//                                       ),
//                                       height: 45,
//                                       decoration: BoxDecoration(
//                                         color: Colors.blue,
//                                         borderRadius: BorderRadius.circular(10),
//                                       ),
//                                       child: Center(
//                                         child: Text(
//                                           "11.50-13.00",
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.w600,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                     SizedBox(width: 5),
//                                     Expanded(
//                                       child: Container(
//                                         margin: EdgeInsets.only(top: 10),
//                                         padding: EdgeInsets.symmetric(
//                                           horizontal: 5,
//                                         ),
//                                         // width: Get.width,
//                                         height: 45,
//                                         decoration: BoxDecoration(
//                                           color: Colors.blue,
//                                           borderRadius: BorderRadius.circular(
//                                             10,
//                                           ),
//                                         ),
//                                         child: Center(
//                                           child: Text(
//                                             "Istirahat II (Sholat Dzuhur & Makan siang)",
//                                             // style: TextStyle(
//                                             //   fontWeight: FontWeight.w600,
//                                             // ),
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),

//                                 FieldJurnal(
//                                   controller: controller,
//                                   controllerNya: controller.ke7C,
//                                   label: "13.00-13.30",
//                                   color: Colors.purple,
//                                   jam: "13.00-13.30",
//                                 ),
//                                 FieldJurnal(
//                                   controller: controller,
//                                   controllerNya: controller.ke8C,
//                                   label: "13.30-14.00",
//                                   color: Colors.purple,
//                                   jam: "13.30-14.00",
//                                 ),
//                                 FieldJurnal(
//                                   controller: controller,
//                                   controllerNya: controller.ke9C,
//                                   label: "14.00-14.30",
//                                   color: Colors.teal,
//                                   jam: "14.00-14.30",
//                                 ),
//                                 FieldJurnal(
//                                   controller: controller,
//                                   controllerNya: controller.ke10C,
//                                   label: "14.30-15.00",
//                                   color: Colors.teal,
//                                   jam: "14.30-15.00",
//                                 ),

//                                 //Sholat Ashar Berjama'ah dan Do'a bersama
//                                 Row(
//                                   children: [
//                                     Container(
//                                       margin: EdgeInsets.only(top: 10),
//                                       padding: EdgeInsets.symmetric(
//                                         horizontal: 5,
//                                       ),
//                                       height: 45,
//                                       decoration: BoxDecoration(
//                                         color: Colors.blue,
//                                         borderRadius: BorderRadius.circular(10),
//                                       ),
//                                       child: Center(
//                                         child: Text(
//                                           "11.50-13.00",
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.w600,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                     SizedBox(width: 5),
//                                     Expanded(
//                                       child: Container(
//                                         margin: EdgeInsets.only(top: 10),
//                                         padding: EdgeInsets.symmetric(
//                                           horizontal: 5,
//                                         ),
//                                         // width: Get.width,
//                                         height: 45,
//                                         decoration: BoxDecoration(
//                                           color: Colors.blue,
//                                           borderRadius: BorderRadius.circular(
//                                             10,
//                                           ),
//                                         ),
//                                         child: Center(
//                                           child: Text(
//                                             "Sholat Ashar Berjama'ah dan Do'a bersama",
//                                             // style: TextStyle(
//                                             //   fontWeight: FontWeight.w600,
//                                             // ),
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           Padding(
//             padding: const EdgeInsets.all(20),
//             child: ElevatedButton(
//               onPressed: () {
//                 // if(controller.nisnC.text.isEmpty){
//                 //   Get.snackbar("Error", "NISN masih kosong");
//                 // }
//                 // else if(controller.namaC.text.isEmpty){
//                 //   Get.snackbar("Error", "nama masih kosong");
//                 // }
//                 // else if(controller.emailC.text.isEmpty){
//                 //   Get.snackbar("Error", "email masih kosong");
//                 // }
//                 // else if(controller.jenisKelamin.value.isEmpty){
//                 //   Get.snackbar("Error", "jenisKelamin masih kosong");
//                 // }
//                 // else if(controller.jabatanC.text.isEmpty){
//                 //   Get.snackbar("Error", "jabatan masih kosong");
//                 // }
//                 // else
//                 {
//                   // controller.tambahSiswa();
//                 }
//               },
//               child: Text("Simpan Jurnal"),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class FieldJurnal extends StatelessWidget {
//   const FieldJurnal({
//     super.key,
//     required this.controller,
//     required this.controllerNya,
//     required this.label,
//     required this.jam,
//     required this.color,
//   });

//   final JurnalAjarHarianController controller;
//   final TextEditingController controllerNya;
//   final String label;
//   final Color color;
//   final String jam;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: EdgeInsets.only(top: 10),
//       child: Row(
//         children: [
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 5),
//             height: 45,
//             decoration: BoxDecoration(
//               color: color,
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Center(
//               child: Text(jam, style: TextStyle(fontWeight: FontWeight.w600)),
//             ),
//           ),
//           SizedBox(width: 5),
//           Expanded(
//             child: TextField(
//               controller: controllerNya,
//               decoration: InputDecoration(
//                 labelText: label,
//                 labelStyle: TextStyle(fontSize: 12),
//                 border: OutlineInputBorder(),
//                 enabledBorder: OutlineInputBorder(
//                   borderSide: BorderSide(color: Colors.grey),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

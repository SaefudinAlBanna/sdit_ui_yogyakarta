// import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'dart:async';
import 'package:intl/intl.dart';

import '../../../routes/app_pages.dart';
import '../controllers/home_controller.dart';

class HomePage extends GetView<HomeController> {
  HomePage({super.key});

  final myItem = [
    ImageSlider(
      image: "assets/pictures/1.jpg",
      ontap: () => Get.snackbar("Informasi", ""),
    ),
    ImageSlider(
      image: "assets/pictures/2.jpg",
      ontap: () => Get.snackbar("Informasi", ""),
    ),
    ImageSlider(
      image: "assets/pictures/3.jpg",
      ontap: () => Get.snackbar("Informasi", ""),
    ),
    ImageSlider(
      image: "assets/pictures/4.jpg",
      ontap: () => Get.snackbar("Informasi", ""),
    ),
    ImageSlider(
      image: "assets/pictures/5.jpg",
      ontap: () => Get.snackbar("Informasi", ""),
    ),
    ImageSlider(
      image: "assets/pictures/6.jpg",
      ontap: () => Get.snackbar("Informasi", ""),
    ),
    ImageSlider(
      image: "assets/pictures/7.jpg",
      ontap: () => Get.snackbar("Informasi", ""),
    ),
    ImageSlider(
      image: "assets/pictures/8.jpg",
      ontap: () => Get.snackbar("Informasi", ""),
    ),
    ImageSlider(
      image: "assets/pictures/9.jpg",
      ontap: () => Get.snackbar("Informasi", ""),
    ),
    ImageSlider(
      image: "assets/pictures/10.jpg",
      ontap: () => Get.snackbar("Informasi", ""),
    ),
    ImageSlider(
      image: "assets/pictures/11.jpg",
      ontap: () => Get.snackbar("Informasi", ""),
    ),
    ImageSlider(
      image: "assets/pictures/12.jpg",
      ontap: () => Get.snackbar("Informasi", ""),
    ),
    ImageSlider(
      image: "assets/pictures/13.jpg",
      ontap: () => Get.snackbar("Informasi", ""),
    ),
    ImageSlider(
      image: "assets/pictures/14.jpg",
      ontap: () => Get.snackbar("Informasi", ""),
    ),
    ImageSlider(
      image: "assets/pictures/15.jpg",
      ontap: () => Get.snackbar("Informasi", ""),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: controller.userStreamBaru(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.data == null || snapshot.data!.data() == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Data tidak ditemukan'),
                Text('Silahkan Logout terlebih dahulu, kemudian Login ulang'),
                SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {
                    controller.signOut();
                    Get.snackbar('Login', 'Silahkan login ulang');
                  },
                  child: Text('Logout'),
                ),
              ],
            ),
          );
        }
        if (snapshot.hasData) {
          Map<String, dynamic> data = snapshot.data!.data()!;
          return Scaffold(
            body: Stack(
              fit: StackFit.passthrough,
              children: [
                ClipPath(
                  clipper: ClassClipPathTop(),
                  child: Container(
                    height: 300,
                    // width: Get.width,
                    decoration: BoxDecoration(
                      color: Colors.indigo[400],
                      image: DecorationImage(
                        image: AssetImage("assets/pictures/sekolah.jpg"),
                      ),
                    ),
                  ),
                ),

                Container(
                  margin: EdgeInsets.only(top: 120),
                  child: Column(
                    children: [
                      Column(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 15),
                            margin: EdgeInsets.symmetric(horizontal: 25),
                            height: 140,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.5),
                                  // spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: Offset(2, 2),
                                ),
                              ],
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: Container(
                              margin: EdgeInsets.only(top: 10),
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.5),
                                    // spreadRadius: 10,
                                    blurRadius: 5,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                                color: Colors.indigo[900],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(height: 10),
                                          Container(
                                            height: 50,
                                            width: 50,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                              image: DecorationImage(
                                                image: NetworkImage(
                                                  "https://ui-avatars.com/api/?name=${data['alias']}",
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            data['alias']
                                                .toString()
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 5),
                                          Text(
                                            data['role'].toString(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  // SizedBox(height: 10),
                                  // Divider(height: 2, color: Colors.black),
                                ],
                              ),
                            ),
                          ),

                          // SizedBox(height: 1),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 15),
                            margin: EdgeInsets.symmetric(horizontal: 25),
                            height: 120,
                            // width: Get.width,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.5),
                                  // spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: Offset(2, 2),
                                ),
                              ],
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              // crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                //KELAS
                                MenuAtas(
                                  title: 'Kelas Ajar',
                                  icon: Icon(Icons.school_outlined),
                                  onTap: () {
                                    Get.defaultDialog(
                                      onCancel: () => Get.back(),
                                      title: 'Kelas Yang Diajar',
                                      content: SizedBox(
                                        height: 200,
                                        width: 200,
                                        // color: Colors.amber,
                                        child: FutureBuilder<List<String>>(
                                          future:
                                              controller
                                                  .getDataKelasYangDiajar(),
                                          // controller.getDataKelasYangDiajar(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return CircularProgressIndicator();
                                            } else if (snapshot.hasData) {
                                              List<String> kelasAjarGuru =
                                                  snapshot.data as List<String>;
                                              return SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: SizedBox(
                                                  // color: Colors.amber,
                                                  child: Row(
                                                    children:
                                                        kelasAjarGuru.map((k) {
                                                          // var kelas = k;
                                                          return SingleChildScrollView(
                                                            scrollDirection:
                                                                Axis.horizontal,
                                                            child: GestureDetector(
                                                              onTap: () {
                                                                Get.back();
                                                                Get.toNamed(
                                                                  Routes
                                                                      .DAFTAR_KELAS,
                                                                  arguments: k,
                                                                );

                                                                // Get.defaultDialog(
                                                                //   onCancel:
                                                                //       () =>
                                                                //           Get.back(),
                                                                //   title:
                                                                //       'Guru mapel kelas',
                                                                //   middleText:
                                                                //       'Pilih Mapel',
                                                                //   content: Column(
                                                                //     children: [
                                                                //       Column(
                                                                //         crossAxisAlignment:
                                                                //             CrossAxisAlignment.start,
                                                                //         children: [
                                                                //           Text(
                                                                //             'Masukan Mapel',
                                                                //             style: TextStyle(
                                                                //               fontSize:
                                                                //                   18,
                                                                //               fontWeight:
                                                                //                   FontWeight.bold,
                                                                //             ),
                                                                //           ),
                                                                //           SizedBox(
                                                                //             height:
                                                                //                 10,
                                                                //           ),
                                                                //           DropdownSearch<
                                                                //             String
                                                                //           >(
                                                                //             decoratorProps: DropDownDecoratorProps(
                                                                //               decoration: InputDecoration(
                                                                //                 border:
                                                                //                     OutlineInputBorder(),
                                                                //                 filled:
                                                                //                     true,
                                                                //                 prefixText:
                                                                //                     'Mapel : ',
                                                                //               ),
                                                                //             ),
                                                                //             selectedItem:
                                                                //                 controller.mapelC.text,
                                                                //             items:
                                                                //                 (f, cs,) => controller.getDataMapel(kelas),
                                                                //             onChanged: (
                                                                //               String?
                                                                //               value,
                                                                //             ) {
                                                                //               controller.mapelC.text = value!;
                                                                //             },
                                                                //             popupProps: PopupProps.menu(
                                                                //               // disabledItemFn: (item) => item == '1A',
                                                                //               fit:
                                                                //                   FlexFit.tight,
                                                                //             ),
                                                                //           ),
                                                                //           SizedBox(
                                                                //             height:
                                                                //                 20,
                                                                //           ),
                                                                //           Center(
                                                                //             child: ElevatedButton(
                                                                //               onPressed: () {
                                                                //                 // ignore: unnecessary_null_comparison
                                                                //                 if (controller.mapelC.text == null ||
                                                                //                     // ignore: unnecessary_null_comparison
                                                                //                     controller.mapelC.text.isEmpty) {
                                                                //                   Get.snackbar(
                                                                //                     'Peringatan',
                                                                //                     'Mapel belum dipilih',
                                                                //                   );
                                                                //                 } else {
                                                                //                   Get.back();
                                                                //                   print("kelas = $kelas");
                                                                //                   Get.toNamed(
                                                                //                     Routes.MAPEL_SISWA, arguments: kelas,
                                                                //                   );
                                                                //                 }
                                                                //               },
                                                                //               style: ElevatedButton.styleFrom(
                                                                //                 padding: EdgeInsets.symmetric(
                                                                //                   horizontal:
                                                                //                       40,
                                                                //                   vertical:
                                                                //                       15,
                                                                //                 ),
                                                                //                 textStyle: TextStyle(
                                                                //                   fontSize:
                                                                //                       16,
                                                                //                 ),
                                                                //               ),
                                                                //               child: Text(
                                                                //                 'Daftar Matapelajaran',
                                                                //               ),
                                                                //             ),
                                                                //           ),
                                                                //         ],
                                                                //       ),
                                                                //     ],
                                                                //   ),
                                                                // );
                                                              },
                                                              child: Container(
                                                                margin:
                                                                    EdgeInsets.only(
                                                                      left: 10,
                                                                    ),
                                                                height: 65,
                                                                width: 55,
                                                                decoration: BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        10,
                                                                      ),
                                                                  color:
                                                                      Colors
                                                                          .indigo[700],
                                                                ),
                                                                child: Center(
                                                                  child: Text(
                                                                    k,
                                                                    style: TextStyle(
                                                                      color:
                                                                          Colors
                                                                              .white,
                                                                      fontSize:
                                                                          14,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        }).toList(),
                                                  ),
                                                ),
                                              );
                                            } else {
                                              return Center(
                                                child: Text(
                                                  "Anda belum memiliki kelas",
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                //HALAQOH
                                MenuAtas(
                                  title: 'Kelas Halaqoh',
                                  icon: Icon(Icons.menu_book_sharp),
                                  onTap: () {
                                    Get.defaultDialog(
                                      onCancel: () => Get.back(),
                                      title: 'Halaqoh Yang Diajar',
                                      content: SizedBox(
                                        height: 200,
                                        width: 200,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: [
                                              FutureBuilder<List<String>>(
                                                future:
                                                    controller
                                                        .getDataKelompok(),
                                                // controller.getDataKelompok(),
                                                builder: (context, snapshot) {
                                                  if (snapshot
                                                          .connectionState ==
                                                      ConnectionState.waiting) {
                                                    return CircularProgressIndicator();
                                                  } else if (snapshot.hasData) {
                                                    // var data = snapshot.data;
                                                    List<String>
                                                    kelompokPengampu =
                                                        snapshot.data
                                                            as List<String>;
                                                    return SingleChildScrollView(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      child: Row(
                                                        children:
                                                            kelompokPengampu.map((
                                                              p,
                                                            ) {
                                                              return GestureDetector(
                                                                onTap: () {
                                                                  Get.back();
                                                                  Get.toNamed(
                                                                    Routes
                                                                        .DAFTAR_HALAQOH_PENGAMPU,
                                                                    arguments:
                                                                        p,
                                                                  );
                                                                },
                                                                child: Container(
                                                                  margin:
                                                                      EdgeInsets.only(
                                                                        left:
                                                                            10,
                                                                      ),
                                                                  height: 65,
                                                                  width: 55,
                                                                  decoration: BoxDecoration(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          10,
                                                                        ),
                                                                    color:
                                                                        Colors
                                                                            .indigo[700],
                                                                  ),
                                                                  child: Center(
                                                                    child: Text(
                                                                      p,
                                                                      style: TextStyle(
                                                                        color:
                                                                            Colors.white,
                                                                        fontSize:
                                                                            14,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                            }).toList(),
                                                      ),
                                                    );
                                                  } else {
                                                    return Center(
                                                      child: SizedBox(
                                                        width: 140,
                                                        child: Center(
                                                          child: Text(
                                                            "Anda belum memiliki kelas Halaqoh",
                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                //EKSKUL
                                MenuAtas(
                                  title: 'Ekskul',
                                  icon: Icon(Icons.sports_gymnastics_rounded),
                                  onTap:
                                      () => Get.defaultDialog(
                                        onCancel: Get.back,
                                        title: 'Ekskul',
                                        middleText: 'Fitur dalam pengembangan',
                                      ),
                                ),
                                //KOORDINATOR HALAQOH
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting)
                                  Center(child: CircularProgressIndicator())
                                else if (snapshot.data!.data()!['role'] ==
                                    'Koordinator Tahfidz')
                                  MenuAtas(
                                    title: 'Input Halaqoh',
                                    icon: Icon(Icons.add_box_outlined),
                                    onTap:
                                        () => Get.toNamed(
                                          Routes.TAMBAH_KELOMPOK_MENGAJI,
                                        ),
                                  ),
                                // JURNAL KELAS GURU
                                MenuAtas(
                                  title: 'jurnal harian ',
                                  icon: Icon(
                                    Icons
                                        .book_outlined, // Use a suitable built-in icon
                                  ),
                                  onTap: () {
                                    Get.toNamed(
                                      Routes.JURNAL_AJAR_HARIAN,
                                      arguments: data,
                                    );
                                  },
                                ),

                                // //KESISWAAN
                                // if (snapshot.connectionState ==
                                //     ConnectionState.waiting)
                                //   Center(child: CircularProgressIndicator())
                                // else if (snapshot.data!.data()!['role'] == 'admin')
                                MenuAtas(
                                  title: 'Input Siswa',
                                  icon: Icon(Icons.person_add_alt),
                                  onTap: () => Get.toNamed(Routes.TAMBAH_SISWA),
                                ),
                                // else
                                //   SizedBox(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // controller.getJamPelajaranSaatIni();
                          controller.test();
                        },
                        child: Text("test"),
                      ),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.symmetric(horizontal: 25),
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 25),

                                // Row(
                                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                //   children: [
                                //     Text(
                                //       'MENU LAINYA',
                                //       textAlign: TextAlign.start,
                                //       style: TextStyle(
                                //         fontSize: 14,
                                //         fontWeight: FontWeight.bold,
                                //       ),
                                //     ),
                                //     TextButton(
                                //       onPressed: () {},
                                //       child: Text(
                                //         "Lihat semua  >",
                                //         style: TextStyle(color: Colors.redAccent),
                                //       ),
                                //     ),
                                //   ],
                                // ),

                                // SingleChildScrollView(
                                //   scrollDirection: Axis.horizontal,
                                //   child: Row(
                                //     children: [
                                //       GestureDetector(
                                //         onTap: () {
                                //           Get.defaultDialog(
                                //             onCancel: Get.back,
                                //             title: "Fitur Menu",
                                //             middleText: "Dalam pengembangan",
                                //           );
                                //         },
                                //         child: Container(
                                //           width: Get.width * 0.7,
                                //           height: 150,
                                //           decoration: BoxDecoration(
                                //             borderRadius: BorderRadius.circular(10),
                                //             image: DecorationImage(
                                //               image: NetworkImage(
                                //                 "https://picsum.photos/id/3/200/300",
                                //               ),
                                //               fit: BoxFit.cover,
                                //             ),
                                //           ),
                                //           // child: Image.asset(
                                //           //   "lib/assets/pictures/1.jpeg",
                                //           //   fit: BoxFit.cover,
                                //           // ),
                                //         ),
                                //       ),
                                //       SizedBox(width: 10),
                                //       GestureDetector(
                                //         onTap: () {
                                //           Get.defaultDialog(
                                //             onCancel: Get.back,
                                //             title: "Fitur Andalan",
                                //             middleText: "Dalam pengembangan",
                                //           );
                                //         },
                                //         child: Container(
                                //           width: Get.width * 0.7,
                                //           height: 150,
                                //           decoration: BoxDecoration(
                                //             borderRadius: BorderRadius.circular(10),
                                //             image: DecorationImage(
                                //               image: NetworkImage(
                                //                 "https://picsum.photos/id/1/200/300",
                                //               ),
                                //               fit: BoxFit.cover,
                                //             ),
                                //           ),
                                //         ),
                                //       ),
                                //       SizedBox(width: 10),
                                //       GestureDetector(
                                //         onTap: () {
                                //           Get.defaultDialog(
                                //             onCancel: Get.back,
                                //             title: "Fitur Istimewa",
                                //             middleText: "Dalam pengembangan",
                                //           );
                                //         },
                                //         child: Container(
                                //           width: Get.width * 0.7,
                                //           height: 150,
                                //           decoration: BoxDecoration(
                                //             borderRadius: BorderRadius.circular(10),
                                //             image: DecorationImage(
                                //               image: NetworkImage(
                                //                 "https://picsum.photos/id/2/200/300",
                                //               ),
                                //               fit: BoxFit.cover,
                                //             ),
                                //           ),
                                //         ),
                                //       ),
                                //     ],
                                //   ),
                                // ),

                                // CarouselSlider(
                                //   options: CarouselOptions(
                                //     height: 150,
                                //     viewportFraction: 1.0,
                                //     aspectRatio: 2 / 1,
                                //     autoPlay: true,
                                //     autoPlayInterval: Duration(seconds: 5),
                                //     // autoPlayAnimationDuration: Duration(milliseconds: 800),
                                //     enlargeCenterPage: true,
                                //   ),
                                //   items: myItem,
                                // ),
                                GetBuilder<HomeController>(
                                  builder: (controller) {
                                    // ignore: unnecessary_null_comparison
                                    if (controller.idTahunAjaran == null) {
                                      return Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    return StreamBuilder<
                                      QuerySnapshot<Map<String, dynamic>>
                                    >(
                                      stream: controller.getDataJurnalKelas(),
                                      builder: (context, snapJurnal) {
                                        if (snapJurnal.connectionState ==
                                            ConnectionState.waiting) {
                                          return Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        }
                                        if (snapJurnal.data == null ||
                                            snapJurnal.data!.docs.isEmpty) {
                                          return Center(
                                            child: Text("Tidak ada data"),
                                          );
                                        }
                                        var dataJurnal = snapJurnal.data!.docs;
                                        return CarouselSlider(
                                          options: CarouselOptions(
                                            height: 150,
                                            viewportFraction: 1.0,
                                            aspectRatio: 2 / 1,
                                            autoPlay: true,
                                            autoPlayInterval: Duration(
                                              seconds: 5,
                                            ),
                                            enlargeCenterPage: true,
                                          ),
                                          items: [
                                            ...dataJurnal.map(
                                              (doc) => Container(
                                                width: Get.width * 0.7,
                                                height: 150,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      doc['namakelas'],
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                    Obx(
                                                      () => 
                                                      StreamBuilder<
                                                        QuerySnapshot<
                                                          Map<String, dynamic>
                                                        >
                                                      >(
                                                        key: ValueKey(controller.jamPelajaranRx.value),
                                                        stream: controller
                                                            .getDataJurnalPerKelas(
                                                              doc.id,
                                                              controller
                                                                  .jamPelajaranRx
                                                                  .value,
                                                              // controller.getJamPelajaranSaatIni()
                                                            ),
                                                        builder: (
                                                          context,
                                                          snapshotJurnalBawah,
                                                        ) {
                                                          if (snapshotJurnalBawah
                                                                  .connectionState ==
                                                              ConnectionState
                                                                  .waiting) {
                                                            return CircularProgressIndicator();
                                                          }
                                                          if (snapshotJurnalBawah
                                                                      .data ==
                                                                  null ||
                                                              snapshotJurnalBawah
                                                                  .data!
                                                                  .docs
                                                                  .isEmpty) {
                                                                    // controller.test();
                                                            print(
                                                              "snapshotJurnalBawah.data = ${snapshotJurnalBawah.data?.docs}",
                                                              
                                                                    
                                                            );
                                                            controller.getDataJurnalPerKelas(doc.id, controller
                                                                  .jamPelajaranRx
                                                                  .value,);
                                                            // print("Tidak ada data");
                                                            return Center(
                                                              child: Text(
                                                                "Tidak ada data nyaa..",
                                                              ),
                                                            );
                                                          }
                                                          if (snapshotJurnalBawah
                                                              .hasData) {
                                                            var dataJurnalBawah =
                                                                snapshotJurnalBawah
                                                                    .data!
                                                                    .docs;
                                                                    // controller.test();
                                                                    controller.getDataJurnalPerKelas(doc.id, controller
                                                                  .jamPelajaranRx
                                                                  .value,);
                                                            // print("dataJurnalBawah = ");
                                                            if (dataJurnalBawah
                                                                .isEmpty) {
                                                              return Text(
                                                                "Tidak ada data jurnal pada jam ini",
                                                                style:
                                                                    TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                    ),
                                                              );
                                                            }
                                                            // Aman mengakses index 0
                                                            // print("dataJurnalBawah = ${dataJurnalBawah[0]['namanya']}");
                                                            return Column(
                                                              children: [
                                                                Text(
                                                                  dataJurnalBawah[0]['jampelajaran']
                                                                      .toString(),
                                                                  style:
                                                                      TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                      ),
                                                                ),
                                                                Text(
                                                                  dataJurnalBawah[0]['namanya']
                                                                      .toString(),
                                                                  style:
                                                                      TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                      ),
                                                                ),
                                                              ],
                                                            );
                                                          }
                                                          return Text(
                                                            "dataSSS",
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),

                                SizedBox(height: 15),
                                Text('MENU ADMIN'),
                                SizedBox(height: 10),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // if (snapshot.connectionState ==
                                    //     ConnectionState.waiting)
                                    //   Center(child: CircularProgressIndicator())
                                    // else if (snapshot.data!.data()!['role'] ==
                                    //     'admin')
                                    MenuBawah(
                                      title: 'Halaqoh',
                                      icon: Icon(Icons.hotel_class_sharp),
                                      onTap:
                                          () => Get.defaultDialog(
                                            onCancel: () => Get.back(),
                                            title: 'Halaqoh Per Fase',
                                            middleText: 'klik tombol fase',
                                            middleTextStyle: TextStyle(
                                              color: Colors.black,
                                              fontSize: 16,
                                            ),
                                            content: SizedBox(
                                              height: 200,
                                              width: 200,
                                              child: SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: Row(
                                                  children: [
                                                    FutureBuilder<List<String>>(
                                                      future:
                                                          controller
                                                              .getDataFase(),
                                                      builder: (
                                                        context,
                                                        snapshot,
                                                      ) {
                                                        if (snapshot
                                                                .connectionState ==
                                                            ConnectionState
                                                                .waiting) {
                                                          return CircularProgressIndicator();
                                                        } else if (snapshot
                                                                    .data ==
                                                                // ignore: prefer_is_empty
                                                                null ||
                                                            snapshot
                                                                    .data
                                                                    ?.length ==
                                                                0) {
                                                          return Center(
                                                            child: SizedBox(
                                                              height: 100,
                                                              width: 170,
                                                              child: Text(
                                                                "Koordinator Tahfidz belum input kelompok",
                                                              ),
                                                            ),
                                                          );
                                                        } else if (snapshot
                                                            .hasData) {
                                                          List<String>
                                                          kelompokPengampu =
                                                              snapshot.data
                                                                  as List<
                                                                    String
                                                                  >;
                                                          return SingleChildScrollView(
                                                            scrollDirection:
                                                                Axis.horizontal,
                                                            child: Row(
                                                              children:
                                                                  kelompokPengampu.map((
                                                                    p,
                                                                  ) {
                                                                    return GestureDetector(
                                                                      onTap: () {
                                                                        Get.back();
                                                                        Get.toNamed(
                                                                          Routes
                                                                              .DAFTAR_HALAQOH_PERFASE,
                                                                          arguments:
                                                                              p,
                                                                        );
                                                                      },
                                                                      child: Container(
                                                                        margin: EdgeInsets.only(
                                                                          left:
                                                                              10,
                                                                        ),
                                                                        height:
                                                                            65,
                                                                        width:
                                                                            55,
                                                                        decoration: BoxDecoration(
                                                                          borderRadius: BorderRadius.circular(
                                                                            10,
                                                                          ),
                                                                          color:
                                                                              Colors.indigo[700],
                                                                        ),
                                                                        child: Center(
                                                                          child: Text(
                                                                            p,
                                                                            style: TextStyle(
                                                                              color:
                                                                                  Colors.white,
                                                                              fontSize:
                                                                                  14,
                                                                              fontWeight:
                                                                                  FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }).toList(),
                                                            ),
                                                          );
                                                        } else {
                                                          return Center(
                                                            child: Text(
                                                              "Belum input Halaqoh",
                                                            ),
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                    ),

                                    // TAMBAH PEGAWAI
                                    // if (snapshot.data!.data()!['role'] == 'admin')
                                    MenuBawah(
                                      title: 'Pegawai',
                                      icon: Icon(Icons.person_add),
                                      onTap: () {
                                        Get.toNamed(Routes.TAMBAH_PEGAWAI);
                                      },
                                    ),
                                    // TAMBAH PESAN GURU KE WALI
                                    MenuBawah(
                                      title: 'Pesan',
                                      icon: Icon(Icons.message_outlined),
                                      onTap: () {},
                                    ),

                                    // TAMBAH MOTIVASI GURU KE WALI
                                    MenuBawah(
                                      title: 'Motivasi',
                                      icon: Icon(
                                        Icons.family_restroom_outlined,
                                      ),
                                      onTap: () {},
                                    ),

                                    // TAMBAH MOTIVASI GURU KE WALI
                                    MenuBawah(
                                      title: 'Sekolah',
                                      icon: Icon(Icons.info_outline),
                                      onTap: () {
                                        // controller.tampilkanSesuaiWaktu(); // 1
                                        // controller.tampilkanSesuaiWaktuDenganDateTime(); // 2
                                      },
                                    ),
                                  ],
                                ),

                                SizedBox(height: 35),
                                Text(
                                  'MENU MANAGEMENT',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Divider(height: 1, color: Colors.black),
                                SizedBox(height: 15),

                                //ISI KOTAKAN MENU
                                //===========================
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      //TAMBAH KELAS
                                      // MenuManagement(
                                      //   title: 'Tambah Kelas',
                                      //   icon: Icon(
                                      //     Icons.format_list_numbered_outlined,
                                      //   ),
                                      //   // onTap: () => Get.toNamed(Routes.TAMBAH_KELAS_BARU),
                                      //   onTap: () {
                                      //     Get.defaultDialog(
                                      //       onCancel: () => Get.back(),
                                      //       title: 'Tambah Kelas Baru',
                                      //       middleText:
                                      //           'Silahkan tambahkan kelas baru',
                                      //       content: Column(
                                      //         children: [
                                      //           Column(
                                      //             crossAxisAlignment:
                                      //                 CrossAxisAlignment.start,
                                      //             children: [
                                      //               Text(
                                      //                 'Masukan Kelas Baru',
                                      //                 style: TextStyle(
                                      //                   fontSize: 18,
                                      //                   fontWeight: FontWeight.bold,
                                      //                 ),
                                      //               ),
                                      //               SizedBox(height: 10),
                                      //               TextField(
                                      //                 textCapitalization:
                                      //                     TextCapitalization
                                      //                         .sentences,
                                      //                 // controller:controller.kelasBaruC,
                                      //                 decoration: InputDecoration(
                                      //                   border: OutlineInputBorder(),
                                      //                   labelText: 'Nama Kelas',
                                      //                 ),
                                      //               ),
                                      //               SizedBox(height: 20),
                                      //               Center(
                                      //                 child: ElevatedButton(
                                      //                   onPressed: () {
                                      //                     // controller
                                      //                     //     .simpanKelasBaru();
                                      //                     // Get.back();
                                      //                   },
                                      //                   style:
                                      //                       ElevatedButton.styleFrom(
                                      //                         padding:
                                      //                             EdgeInsets.symmetric(
                                      //                               horizontal: 40,
                                      //                               vertical: 15,
                                      //                             ),
                                      //                         textStyle: TextStyle(
                                      //                           fontSize: 16,
                                      //                         ),
                                      //                       ),
                                      //                   child: Text('Simpan'),
                                      //                 ),
                                      //               ),
                                      //             ],
                                      //           ),
                                      //         ],
                                      //       ),
                                      //     );
                                      //   },
                                      //   colors: Colors.red,
                                      // ),
                                      // TAMBAH TAHUN AJARAN
                                      MenuManagement(
                                        title: 'Tahun Ajaran',
                                        icon: Icon(
                                          Icons.calendar_month_outlined,
                                        ),
                                        onTap: () {
                                          Get.defaultDialog(
                                            onCancel: () => Get.back(),
                                            title: 'Tahun Ajaran Baru',
                                            middleText:
                                                'Silahkan tambahkan tahun ajaran baru',
                                            content: Column(
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'tahun ajaran baru',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    SizedBox(height: 10),
                                                    TextField(
                                                      textCapitalization:
                                                          TextCapitalization
                                                              .sentences,
                                                      controller:
                                                          controller
                                                              .tahunAjaranBaruC,
                                                      decoration: InputDecoration(
                                                        border:
                                                            OutlineInputBorder(),
                                                        labelText:
                                                            'Tahun Ajaran',
                                                      ),
                                                    ),
                                                    SizedBox(height: 20),
                                                    Center(
                                                      child: ElevatedButton(
                                                        onPressed: () {
                                                          controller
                                                              .simpanTahunAjaran();
                                                          Get.back();
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 40,
                                                                vertical: 15,
                                                              ),
                                                          textStyle: TextStyle(
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                        child: Text('Simpan'),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        colors: Colors.indigo.shade600,
                                      ),
                                      MenuManagement(
                                        title: 'Input Halaqoh',
                                        icon: Icon(Icons.add_box_outlined),
                                        onTap:
                                            () => Get.offAllNamed(
                                              Routes.TAMBAH_KELOMPOK_MENGAJI,
                                            ),
                                        colors: Colors.green.shade700,
                                      ),
                                      MenuManagement(
                                        title: 'Input Siswa',
                                        icon: Icon(Icons.person_add_alt),
                                        onTap:
                                            () => Get.toNamed(
                                              Routes.TAMBAH_SISWA,
                                            ),
                                        colors: Colors.deepOrange.shade600,
                                      ),
                                      MenuManagement(
                                        title: 'Input Kelas',
                                        icon: Icon(
                                          Icons.account_balance_rounded,
                                        ),
                                        onTap: () {
                                          Get.defaultDialog(
                                            onCancel: () => Get.back(),
                                            title: 'Tambah Kelas Baru',
                                            middleText:
                                                'Silahkan tambahkan kelas baru',
                                            content: Column(
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Masukan Kelas Baru',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    SizedBox(height: 10),
                                                    DropdownSearch<String>(
                                                      decoratorProps:
                                                          DropDownDecoratorProps(
                                                            decoration:
                                                                InputDecoration(
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                  filled: true,
                                                                  prefixText:
                                                                      'kelas : ',
                                                                ),
                                                          ),
                                                      selectedItem:
                                                          controller
                                                              .kelasSiswaC
                                                              .text,
                                                      items:
                                                          (f, cs) =>
                                                              controller
                                                                  .getDataKelas(),
                                                      onChanged: (
                                                        String? value,
                                                      ) {
                                                        controller
                                                            .kelasSiswaC
                                                            .text = value!;
                                                      },
                                                      popupProps: PopupProps.menu(
                                                        // disabledItemFn: (item) => item == '1A',
                                                        fit: FlexFit.tight,
                                                      ),
                                                    ),
                                                    SizedBox(height: 20),
                                                    Center(
                                                      child: ElevatedButton(
                                                        onPressed: () {
                                                          // ignore: unnecessary_null_comparison
                                                          if (controller
                                                                  .kelasSiswaC
                                                                  .text
                                                                  .isEmpty ||
                                                              // ignore: unnecessary_null_comparison
                                                              controller
                                                                      .kelasSiswaC
                                                                      .text ==
                                                                  null) {
                                                            Get.snackbar(
                                                              'Peringatan',
                                                              'Kelas belum dipilih',
                                                            );
                                                          } else {
                                                            Get.back();
                                                            Get.toNamed(
                                                              Routes
                                                                  .PEMBERIAN_KELAS_SISWA,
                                                              arguments:
                                                                  controller
                                                                      .kelasSiswaC
                                                                      .text,
                                                            );
                                                          }
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 40,
                                                                vertical: 15,
                                                              ),
                                                          textStyle: TextStyle(
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'Pilih siswa',
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        colors: Colors.grey.shade800,
                                      ),
                                      MenuManagement(
                                        title: 'Update Kelas',
                                        icon: Icon(Icons.account_tree_outlined),
                                        onTap: () {
                                          Get.defaultDialog(
                                            onCancel: () => Get.back(),
                                            title: 'Guru mapel kelas',
                                            middleText:
                                                'Silahkan masukan kelas',
                                            content: Column(
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Masukan Kelas',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    SizedBox(height: 10),
                                                    DropdownSearch<String>(
                                                      decoratorProps:
                                                          DropDownDecoratorProps(
                                                            decoration:
                                                                InputDecoration(
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                  filled: true,
                                                                  prefixText:
                                                                      'kelas : ',
                                                                ),
                                                          ),
                                                      selectedItem:
                                                          controller
                                                              .kelasSiswaC
                                                              .text,
                                                      items:
                                                          (f, cs) =>
                                                              controller
                                                                  .getDataKelas(),
                                                      onChanged: (
                                                        String? value,
                                                      ) {
                                                        controller
                                                            .kelasSiswaC
                                                            .text = value!;
                                                      },
                                                      popupProps: PopupProps.menu(
                                                        // disabledItemFn: (item) => item == '1A',
                                                        fit: FlexFit.tight,
                                                      ),
                                                    ),
                                                    SizedBox(height: 20),
                                                    Center(
                                                      child: ElevatedButton(
                                                        onPressed: () {
                                                          // ignore: unnecessary_null_comparison
                                                          if (controller
                                                                  .kelasSiswaC
                                                                  .text
                                                                  .isEmpty ||
                                                              // ignore: unnecessary_null_comparison
                                                              controller
                                                                      .kelasSiswaC
                                                                      .text ==
                                                                  null) {
                                                            Get.snackbar(
                                                              'Peringatan',
                                                              'Kelas belum dipilih',
                                                            );
                                                          } else {
                                                            Get.back();
                                                            Get.toNamed(
                                                              Routes
                                                                  .PEMBERIAN_GURU_MAPEL,
                                                              arguments:
                                                                  controller
                                                                      .kelasSiswaC
                                                                      .text,
                                                            );
                                                          }
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 40,
                                                                vertical: 15,
                                                              ),
                                                          textStyle: TextStyle(
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'Daftar Matapelajaran',
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        // Get.toNamed(Routes.UPDATE_KELAS_TAHUN_AJARAN),
                                        colors: Colors.teal.shade700,
                                      ),
                                    ],
                                  ),
                                ),

                                //>>>>>>>>>>>>>>>>
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return Text('Data Kosong');
        }
      },
    );
  }
}

class ImageSlider extends StatelessWidget {
  const ImageSlider({super.key, required this.image, required this.ontap});

  final String image;
  final Function() ontap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ontap,
      child: Container(
        width: Get.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          image: DecorationImage(image: AssetImage(image), fit: BoxFit.fill),
        ),
      ),
    );
  }
}

class MenuAtas extends StatelessWidget {
  const MenuAtas({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final Icon icon;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 10),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.indigo.shade500,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(icon.icon, size: 40, color: Colors.white),
              ),
            ),
          ),
          SizedBox(height: 3),
          SizedBox(
            width: 55,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class MenuBawah extends StatelessWidget {
  const MenuBawah({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final Icon icon;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.indigo.shade500,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(icon.icon, size: 40, color: Colors.white),
              ),
            ),
          ),
          SizedBox(height: 3),
          SizedBox(
            width: 55,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class MenuManagement extends StatelessWidget {
  const MenuManagement({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    required this.colors,
  });

  final String title;
  final Icon icon;
  final Function() onTap;
  final Color colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: colors,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(icon.icon, size: 40, color: Colors.white),
              ),
            ),
          ),
          SizedBox(height: 3),
          SizedBox(
            width: 55,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class ItemMenu extends StatelessWidget {
  const ItemMenu({super.key, required this.title, required this.icon});

  final String title;
  final Icon icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 40, width: 40, child: icon),
        SizedBox(height: 5),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15),
        ),
      ],
    );
  }
}

class ClipPathClass extends CustomClipper<Path> {
  @override
  getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width - 50, size.height);
    path.lineTo(size.width, size.height - 50);

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper oldClipper) => false;
}

class ClassClipPathTop extends CustomClipper<Path> {
  @override
  getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper oldClipper) => false;
}

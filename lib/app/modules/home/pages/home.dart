// import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// import 'dart:async';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

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
            body: SafeArea(
              child: ListView(
                children: [
                  Stack(
                    fit: StackFit.passthrough,
                    children: [
                      ClipPath(
                        clipper: ClassClipPathTop(),
                        child: Container(
                          height: 300,
                          // width: Get.width,
                          decoration: BoxDecoration(
                            // color: Colors.indigo[400],
                            color: Colors.green[100],
                            image: DecorationImage(
                              image: AssetImage("assets/png/latar2.png"),
                              fit: BoxFit.cover,
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
                                        color: Colors.grey.withValues(
                                          alpha: 0.5,
                                        ),
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
                                          color: Colors.grey.withValues(
                                            alpha: 0.5,
                                          ),
                                          // spreadRadius: 10,
                                          blurRadius: 5,
                                          offset: Offset(2, 2),
                                        ),
                                      ],
                                      // color: Colors.indigo[900],
                                      color: Colors.green[700],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                                        BorderRadius.circular(
                                                          50,
                                                        ),
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

                                // MENU ATAS PROFILE
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 15),
                                  margin: EdgeInsets.symmetric(horizontal: 25),
                                  height: 135,
                                  // width: Get.width,
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withValues(
                                          alpha: 0.5,
                                        ),
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
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      // crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        
                                        //KELAS
                                        MenuAtas(
                                          title: 'Kelas Ajar',
                                          // icon: Icon(Icons.school_outlined),
                                          gambar: "assets/png/tas.png",
                                          onTap: () {
                                            Get.defaultDialog(
                                              onCancel: () => Get.back(),
                                              title: 'Kelas Yang Diajar',
                                              content: SizedBox(
                                                height: 200,
                                                width: 200,
                                                // color: Colors.amber,
                                                child: FutureBuilder<
                                                  List<String>
                                                >(
                                                  future:
                                                      controller
                                                          .getDataKelasYangDiajar(),
                                                  // controller.getDataKelasYangDiajar(),
                                                  builder: (context, snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return CircularProgressIndicator();
                                                    } else if (snapshot
                                                        .hasData) {
                                                      List<String>
                                                      kelasAjarGuru =
                                                          snapshot.data
                                                              as List<String>;
                                                      return SingleChildScrollView(
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        child: SizedBox(
                                                          // color: Colors.amber,
                                                          child: Row(
                                                            children:
                                                                kelasAjarGuru.map((
                                                                  k,
                                                                ) {
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
                                                                          arguments:
                                                                              k,
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
                                                                            k,
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

                                        // CATATAN SISWA UNTUK KEPSEK
                                        MenuAtas(
                                          title: "Catatan Siswa",
                                          gambar: "assets/png/update_waktu.png",
                                          onTap: () {
                                            Get.defaultDialog(
                                              onCancel: () { 
                                                controller.clearForm();
                                                Get.back();},
                                              title: 'Kelas',
                                              // middleText:
                                              //     'Silahkan masukan kelas',
                                              content: Column(
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      DropdownSearch<String>(
                                                        decoratorProps:
                                                            DropDownDecoratorProps(
                                                              decoration:
                                                                  InputDecoration(
                                                                    border:
                                                                        OutlineInputBorder(),
                                                                    filled:
                                                                        true,
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
                                                                controller.kelasSiswaC.text == null) {
                                                              Get.snackbar(
                                                                'Peringatan',
                                                                'Kelas belum dipilih',
                                                              );
                                                            } else {
                                                              Get.back();

                                                              Get.toNamed(
                                                                Routes
                                                                    .TANGGAPAN_CATATAN_KHUSUS_SISWA,
                                                                arguments:
                                                                    controller
                                                                        .kelasSiswaC
                                                                        .text,
                                                              );
                                                              controller.clearForm();
                                                            }
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      40,
                                                                  vertical: 15,
                                                                ),
                                                            textStyle:
                                                                TextStyle(
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
                                        ),
                                        
                                        // CATATAN SISWA UNTUK WALIKELAS
                                        MenuAtas(
                                          title: "Catatan Siswa",
                                          gambar: "assets/png/daftar_list.png",
                                          onTap: () async {
                                            // Tunggu hasil Future
                                            final kelasWali =
                                                await controller
                                                    .getDataKelasWali();
                                            if (kelasWali != null) {
                                              Get.toNamed(
                                                Routes
                                                    .TANGGAPAN_CATATAN_KHUSUS_SISWA_WALIKELAS,
                                                arguments: kelasWali,
                                              );
                                            } else {
                                              Get.snackbar(
                                                'Informasi',
                                                'Tidak ada catatan dalam kelas anda.',
                                              );
                                            }
                                          },
                                        ),

                                        //KELAS HALAQOH
                                        MenuAtas(
                                          title: 'Kelas Halaqoh',
                                          // icon: Icon(Icons.menu_book_sharp),
                                          gambar: "assets/png/papan_list.png",
                                          onTap: () {
                                            Get.defaultDialog(
                                              onCancel: () => Get.back(),
                                              title: 'Halaqoh Yang Diajar',
                                              content: SizedBox(
                                                height: 200,
                                                width: 200,
                                                child: SingleChildScrollView(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  child: Row(
                                                    children: [
                                                      FutureBuilder<
                                                        List<String>
                                                      >(
                                                        future:
                                                            controller
                                                                .getDataKelompok(),
                                                        // controller.getDataKelompok(),
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
                                                              .hasData) {
                                                            // var data = snapshot.data;
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
                                                                            Routes.DAFTAR_HALAQOH_PENGAMPU,
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

                                        // PEMBAYARAN SPP (ADMIN)
                                        MenuAtas(title: "Bayar SPP", gambar: "assets/png/uang.png", onTap: (){
                                          Get.defaultDialog(
                                              onCancel: () { 
                                                controller.clearForm();
                                                Get.back();},
                                              title: 'Kelas',
                                              content: Column(
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      
                                                      DropdownSearch<String>(
                                                        decoratorProps:
                                                            DropDownDecoratorProps(
                                                              decoration:InputDecoration(
                                                                    border: OutlineInputBorder(),
                                                                    filled:
                                                                        true,
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
                                                                controller.kelasSiswaC.text == null) {
                                                              Get.snackbar(
                                                                'Peringatan',
                                                                'Kelas belum dipilih',
                                                              );
                                                            } else {
                                                              Get.back();
                                                              Get.toNamed(
                                                                Routes
                                                                    .PEMBAYARAN_SPP,
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
                                                                  horizontal:
                                                                      40,
                                                                  vertical: 15,
                                                                ),
                                                            textStyle:
                                                                TextStyle(
                                                                  fontSize: 16,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            'Daftar Siswa',
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            );
                                        }),
                                        
                                        //EKSKUL
                                        MenuAtas(
                                          title: 'Ekskul',
                                          // icon: Icon(Icons.sports_gymnastics_rounded),
                                          gambar: "assets/png/buku_uang.png",
                                          onTap: () => controller.test(),
                                              // () => Get.defaultDialog(
                                              //   onCancel: Get.back,
                                              //   title: 'Ekskul',
                                              //   middleText:
                                              //       'Fitur dalam pengembangan',
                                              // ),
                                        ),

                                        //TAMBAH HALAQOH (KOORDINATOR HALAQOH)
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting)
                                          Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        else if (snapshot.data!
                                                .data()!['role'] ==
                                            'Koordinator Tahfidz')
                                          MenuAtas(
                                            title: 'Tambah Halaqoh',
                                            // icon: Icon(Icons.add_box_outlined),
                                            gambar:
                                                "assets/png/daftar_list.png",
                                            onTap:
                                                () => Get.toNamed(
                                                  Routes
                                                      .TAMBAH_KELOMPOK_MENGAJI,
                                                ),
                                          ),

                                        // CEK HALAQOH (KOORDINATOR TAHFIDZ)
                                        MenuAtas(
                                          title: 'Tahsin Tahfidz',
                                          // icon: Icon(Icons.hotel_class_sharp),
                                          gambar: "assets/png/daftar_tes.png",
                                          onTap:
                                              () => Get.defaultDialog(
                                                onCancel: () { 
                                                  // controller.clearForm();
                                                  Get.back();},
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
                                                        FutureBuilder<
                                                          List<String>
                                                        >(
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
                                                                              Routes.DAFTAR_HALAQOH_PERFASE,
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

                                        // JURNAL KELAS GURU (GURU KELAS & MAPEL)
                                        MenuAtas(
                                          title: 'jurnal harian ',
                                          // icon: Icon(Icons .book_outlined),
                                          gambar: "assets/png/faq.png",
                                          onTap: () {
                                            Get.toNamed(
                                              Routes.JURNAL_AJAR_HARIAN,
                                              arguments: data,
                                            );
                                          },
                                        ),

                                        
                                        // TAMBAH SISWA (TU)
                                        // if (snapshot.connectionState ==
                                        //     ConnectionState.waiting)
                                        //   Center(child: CircularProgressIndicator())
                                        // else if (snapshot.data!.data()!['role'] == 'admin')
                                        MenuAtas(
                                          title: 'Tambah Siswa',
                                          // icon: Icon(Icons.person_add_alt),
                                          gambar: "assets/png/jurnal_ajar.png",
                                          onTap:
                                              () => Get.toNamed(
                                                Routes.TAMBAH_SISWA,
                                              ),
                                        ),

                                        // TAMBAH PEGAWAI (TU)
                                        MenuAtas(
                                          title: 'Tambah Pegawai',
                                          // icon: Icon(Icons.person_add),
                                          gambar: "assets/png/kamera_layar.png",
                                          onTap: () {
                                            Get.toNamed(Routes.TAMBAH_PEGAWAI);
                                          },
                                        ),

                                        // SISWA PINDAH (TU)
                                        MenuAtas(
                                          title: 'Pindah Siswa',
                                          // icon: Icon(Icons.change_circle_outlined),
                                          gambar: "assets/png/ktp.png",
                                          onTap: () {},
                                        ),

                                        // TAHUN AJARAN (TU)
                                        MenuAtas(
                                          title: 'Tahun Ajaran',
                                          // icon: Icon(Icons.calendar_month_outlined),
                                          gambar: "assets/png/layar_list.png",
                                          onTap: () {
                                            Get.defaultDialog(
                                              onCancel: () { 
                                                controller.clearForm();
                                                Get.back();},
                                              title: 'Tahun Ajaran Baru',
                                              middleText:
                                                  'Silahkan tambahkan tahun ajaran baru',
                                              content: Column(
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
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
                                                                  horizontal:
                                                                      40,
                                                                  vertical: 15,
                                                                ),
                                                            textStyle:
                                                                TextStyle(
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
                                        ),

                                        // TAMBAH KELAS (TU)
                                        MenuAtas(
                                          title: 'Tambah Kelas',
                                          // icon: Icon(Icons.account_balance_rounded),
                                          gambar: "assets/png/layar.png",
                                          onTap: () {
                                            Get.defaultDialog(
                                              onCancel: () { 
                                                controller.clearForm();
                                                Get.back();},
                                              title: 'Tambah Kelas Baru',
                                              middleText:
                                                  'Silahkan tambahkan kelas baru',
                                              content: Column(
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
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
                                                                    filled:
                                                                        true,
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
                                                                controller.kelasSiswaC.text == null) {
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
                                                               controller.clearForm();
                                                            }
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      40,
                                                                  vertical: 15,
                                                                ),
                                                            textStyle:
                                                                TextStyle(
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
                                        ),

                                        // UBAH KELAS (TU)
                                        MenuAtas(
                                          title: 'Ubah Kelas',
                                          // icon: Icon(Icons.account_tree_outlined),
                                          gambar: "assets/png/list_nilai.png",
                                          onTap: () {
                                            Get.defaultDialog(
                                              onCancel: () { 
                                                controller.clearForm();
                                                Get.back();},
                                              title: 'Guru mapel kelas',
                                              middleText:
                                                  'Silahkan masukan kelas',
                                              content: Column(
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
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
                                                                    filled:
                                                                        true,
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
                                                                    .getDataKelasMapel(),
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
                                                                controller.kelasSiswaC.text == null) {
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
                                                               controller.clearForm();
                                                            }
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      40,
                                                                  vertical: 15,
                                                                ),
                                                            textStyle:
                                                                TextStyle(
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
                                        ),

                                        // INPUT JADWAL (KURIKULUM)
                                        MenuAtas(
                                          title: 'Buat Jadwal',
                                          // icon: Icon(Icons.book),
                                          gambar: "assets/png/papan_list.png",
                                          onTap: () {
                                            Get.toNamed(Routes.BUAT_JADWAL_PELAJARAN);
                                          },
                                        ),

                                        // LIHAT JADWAL (SEMUA)
                                        MenuAtas(
                                          title: 'Jadwal Pelajaran',
                                          // icon: Icon(Icons.schedule_outlined),
                                          gambar: "assets/png/pengumuman.png",
                                          onTap: () {
                                            Get.toNamed(Routes.JADWAL_PELAJARAN);
                                          },
                                        ),

                                        // BUKU PEGANGAN (BIASANYA GURU & KURIKULUM)
                                        MenuAtas(
                                          title: 'Buku Pegangan',
                                          // icon: Icon(Icons.book_outlined),
                                          gambar: "assets/png/pesan.png",
                                          onTap: () {},
                                        ),

                                        // BUAT SARPRAS SEKOLAH (KEPALA SEKOLAH)
                                        MenuAtas(
                                          title: 'Buat Sarpras Sekolah',
                                          // icon: Icon(Icons.zoom_out_outlined),
                                          gambar: "assets/png/tumpukan_buku.png",
                                          onTap: () {
                                            Get.toNamed(Routes.BUAT_SARPRAS);
                                          },
                                        ),

                                        // INFO SARPRAS SEKOLAH (KEPALA SEKOLAH)
                                        MenuAtas(
                                          title: 'Sarpras Sekolah',
                                          // icon: Icon(Icons.zoom_out_outlined),
                                          gambar: "assets/png/toga_lcd.png",
                                          onTap: () {
                                            Get.toNamed(Routes.DATA_SARPRAS);
                                          },
                                        ),

                                        // CATATAN KHUSUS SISWA (KESISWAAN / BK)
                                        MenuAtas(
                                          title: 'Catatan Khusus Siswa',
                                          // icon: Icon( Icons.broadcast_on_home_outlined),
                                          gambar: "assets/png/play.png",
                                          onTap: () {
                                            Get.defaultDialog(
                                              onCancel: () { 
                                                controller.clearForm();
                                                Get.back();},
                                              title: 'Kelas',
                                              content: Column(
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      
                                                      DropdownSearch<String>(
                                                        decoratorProps:
                                                            DropDownDecoratorProps(
                                                              decoration:
                                                                  InputDecoration(
                                                                    border:
                                                                        OutlineInputBorder(),
                                                                    filled:
                                                                        true,
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
                                                                controller.kelasSiswaC.text == null) {
                                                              Get.snackbar(
                                                                'Peringatan',
                                                                'Kelas belum dipilih',
                                                              );
                                                            } else {
                                                              Get.back();
                                                              Get.toNamed(
                                                                Routes
                                                                    .DAFTAR_SISWA_PERKELAS,
                                                                arguments:
                                                                    controller
                                                                        .kelasSiswaC
                                                                        .text,
                                                              );
                                                               controller.clearForm();
                                                            }
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      40,
                                                                  vertical: 15,
                                                                ),
                                                            textStyle:
                                                                TextStyle(
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
                                        ),

                                        // DAFTAR SEMUA SISWA (KEPALA SEKOLAH / BK)
                                        MenuAtas(
                                          title: 'Daftar Siswa',
                                          // icon: Icon(Icons.account_box_outlined),
                                          gambar: "assets/png/surat.png",
                                          onTap: () {},
                                        ),

                                        // INPUT INFO (KEPALA SEKOLAH & BK & TU & KOOR TAHFIDZ)
                                        MenuAtas(
                                          title: 'Tambah Info',
                                          // icon: Icon(Icons.info_outline),
                                          gambar:
                                              "assets/png/tumpukan_buku.png",
                                          onTap: () {
                                            Get.toNamed(
                                              Routes.INPUT_INFO_SEKOLAH,
                                            );
                                          },
                                        ),

                                        // HAPUS PEGAWAI (KEPALA SEKOLAH & TU)
                                        MenuAtas(
                                          title: 'Hapus Pegawai',
                                          // icon: Icon(Icons.delete),
                                          gambar: "assets/png/update_waktu.png",
                                          onTap: () {},
                                        ),

                                        
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),


                             // AWAL CAROUSEL JURNAL DI KOMEN

                            // CAROUSEL JURNAL
                            // Column(
                            //   crossAxisAlignment: CrossAxisAlignment.start,
                            //   children: [
                            //     SizedBox(height: 25),
                            //     GetBuilder<HomeController>(
                            //       builder: (controller) {
                            //         // ignore: unnecessary_null_comparison
                            //         if (controller.idTahunAjaran == null) {
                            //           return Center(
                            //             child: CircularProgressIndicator(),
                            //           );
                            //         }
                            //         return StreamBuilder<
                            //           QuerySnapshot<Map<String, dynamic>>
                            //         >(
                            //           stream: controller.getDataJurnalKelas(),
                            //           builder: (context, snapJurnal) {
                            //             if (snapJurnal.connectionState ==
                            //                 ConnectionState.waiting) {
                            //               return Center(
                            //                 child: CircularProgressIndicator(),
                            //               );
                            //             }
                            //             if (snapJurnal.data == null ||
                            //                 snapJurnal.data!.docs.isEmpty) {
                            //               return Center(
                            //                 // child: Lottie.asset('assets/lotties/jurnal_loading.json'),
                            //                 child: Text("Belum ada kelas"),
                            //               );
                            //             }
                            //             var dataJurnal = snapJurnal.data!.docs;
                            //             return CarouselSlider(
                            //               options: CarouselOptions(
                            //                 height: 150,
                            //                 viewportFraction: 1.0,
                            //                 aspectRatio: 2 / 1,
                            //                 autoPlay: true,
                            //                 autoPlayInterval: Duration(
                            //                   seconds: 5,
                            //                 ),
                            //                 enlargeCenterPage: true,
                            //               ),
                            //               items: [
                            //                 ...dataJurnal.map(
                            //                   (doc) => Container(
                            //                     width: Get.width * 0.7,
                            //                     height: 150,
                            //                     decoration: BoxDecoration(
                            //                       borderRadius:
                            //                           BorderRadius.circular(10),
                            //                     ),
                            //                     child: Column(
                            //                       children: [
                            //                         Text(
                            //                           doc['namakelas'],
                            //                           style: TextStyle(
                            //                             fontSize: 18,
                            //                           ),
                            //                         ),
                            //                         Obx(
                            //                           () => StreamBuilder<
                            //                             QuerySnapshot<
                            //                               Map<String, dynamic>
                            //                             >
                            //                           >(
                            //                             key: ValueKey(
                            //                               controller
                            //                                   .jamPelajaranRx
                            //                                   .value,
                            //                             ),
                            //                             stream: controller
                            //                                 .getDataJurnalPerKelas(
                            //                                   doc.id,
                            //                                   controller
                            //                                       .jamPelajaranRx
                            //                                       .value,
                            //                                   // controller.getJamPelajaranSaatIni()
                            //                                 ),
                            //                             builder: (
                            //                               context,
                            //                               snapshotJurnalBawah,
                            //                             ) {
                            //                               if (snapshotJurnalBawah
                            //                                       .connectionState ==
                            //                                   ConnectionState
                            //                                       .waiting) {
                            //                                 return CircularProgressIndicator();
                            //                               }
                            //                               if (snapshotJurnalBawah
                            //                                       .data ==
                            //                                       null ||
                            //                                   snapshotJurnalBawah
                            //                                       .data!
                            //                                       .docs
                            //                                       .isEmpty) {
                            //                                 // controller.test();
                            //                                 print("snapshotJurnalBawah.data = ${snapshotJurnalBawah.data?.docs}");
                            //                                 controller
                            //                                     .getDataJurnalPerKelas(
                            //                                       doc.id,
                            //                                       controller
                            //                                           .jamPelajaranRx
                            //                                           .value,
                            //                                     );
                            //                                 // print("Tidak ada data");
                            //                                 return Center(
                            //                                   child: SizedBox(
                            //                                     height: 100,
                            //                                     width: 100,
                            //                                     child: Lottie.asset(
                            //                                       'assets/lotties/jurnal_loading.json',
                            //                                       fit:
                            //                                           BoxFit
                            //                                               .contain,
                            //                                     ),
                            //                                   ),
                            //                                 );
                            //                               }
                            //                               if (snapshotJurnalBawah
                            //                                   .hasData) {
                            //                                 var dataJurnalBawah =
                            //                                     snapshotJurnalBawah
                            //                                         .data!
                            //                                         .docs;
                            //                                 // controller.test();
                            //                                 controller
                            //                                     .getDataJurnalPerKelas(
                            //                                       doc.id,
                            //                                       controller
                            //                                           .jamPelajaranRx
                            //                                           .value,
                            //                                     );
                            //                                 print("dataJurnalBawah = ");
                            //                                 if (dataJurnalBawah
                            //                                     .isEmpty) {
                            //                                   return Text(
                            //                                     "Tidak ada data jurnal pada jam ini",
                            //                                     style:
                            //                                         TextStyle(
                            //                                           fontSize:
                            //                                               14,
                            //                                         ),
                            //                                   );
                            //                                 }
                            //                                 // Aman mengakses index 0
                            //                                 print("dataJurnalBawah = ${dataJurnalBawah[0]['materipelajaran']}");
                            //                                 return Container(
                            //                                   color:
                            //                                       Colors.amber,
                            //                                   child: Column(
                            //                                     children: [
                            //                                       Text(
                            //                                         dataJurnalBawah[0]['jampelajaran']
                            //                                             .toString(),
                            //                                         style: TextStyle(
                            //                                           fontSize:
                            //                                               14,
                            //                                         ),
                            //                                       ),
                            //                                       Text(
                            //                                         dataJurnalBawah[0]['materipelajaran']
                            //                                             .toString(),
                            //                                         style: TextStyle(
                            //                                           fontSize:
                            //                                               14,
                            //                                         ),
                            //                                       ),
                            //                                     ],
                            //                                   ),
                            //                                 );
                            //                               }
                            //                               return Text(
                            //                                 "dataSSS",
                            //                               );
                            //                             },
                            //                           ),
                            //                         ),
                            //                       ],
                            //                     ),
                            //                   ),
                            //                 ),
                            //               ],
                            //             );
                            //           },
                            //         );
                            //       },
                            //     ),
                            //   ],
                            // ),

                            // AKHIR CAROUSEL JURNAL DI KOMEN

                          // REKOMENDASI AI
                          // ================================
                           // --- AWAL BAGIAN JURNAL CAROUSEL AI ---
                            Padding(
                            padding: const EdgeInsets.only(left: 20, top: 20, bottom: 10, right: 20),

                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Jurnal Kelas Hari Ini", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Obx(() => Text(controller.jamPelajaranRx.value, style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
                              ],
                            ),
                          ),

                           Obx(() { // Obx untuk merebuild saat isLoadingInitialData atau kelasAktifList berubah
                                  if (controller.isLoadingInitialData.value) {
                              return SizedBox(
                                height: 150,
                                child: Center(child: CircularProgressIndicator(key: ValueKey("jurnalLoaderInitial"))),
                              );
                            }
                            if (controller.idTahunAjaran == null) {
                              return SizedBox(
                                height: 150,
                                child: Center(child: Text("Tahun ajaran tidak termuat.")),
                              );
                            }
                            if (controller.kelasAktifList.isEmpty) {
                              return SizedBox(
                                height: 150,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Lottie.asset('assets/lotties/empty.json', height: 80), // Ganti dengan Lottie yang sesuai
                                      Icon(Icons.class_outlined, size: 50, color: Colors.grey[400]),
                                      SizedBox(height: 8),
                                      Text("Tidak ada kelas aktif ditemukan."),
                                    ],
                                  ),
                                  ),
                              );
                            }
                           

                            // Carousel hanya dibangun jika ada kelas
                             return CarouselSlider(
                              options: CarouselOptions(
                                height: 170, // Sesuaikan tinggi
                                viewportFraction: 0.9,
                                autoPlay: true, // Matikan autoplay agar user bisa fokus
                                enlargeCenterPage: true,
                                enableInfiniteScroll: controller.kelasAktifList.length > 1,
                              ),
                              items: controller.kelasAktifList.map((docKelas) {
                                final String idKelas = docKelas.id;
                                final String namaKelas = docKelas.data()?['namakelas'] ?? 'Nama Kelas Tdk Ada';
                                return Builder( // Builder diperlukan agar context benar untuk Obx dalam map
                                  builder: (BuildContext context) {
                                    return Container(
                                      width: MediaQuery.of(context).size.width,
                                       margin: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white, // Ganti warna dasar kartu
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.2),
                                            spreadRadius: 1,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            namaKelas,
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                                          ),
                                          Divider(height: 15),
                                          Expanded( // Agar konten jurnal mengisi sisa ruang
                                          child: Obx(() { // Obx untuk jamPelajaranRx
                                          String currentJamDocId = controller.jamPelajaranRx.value;

                                          if (currentJamDocId == 'Memuat jam...' || currentJamDocId.isEmpty) {
                                                return Center(child: Text(currentJamDocId, style: TextStyle(color: Colors.grey)));
                                              }
                                              if (currentJamDocId == 'Tidak ada jam pelajaran') {
                                                return Center(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.access_time_filled, size: 30, color: Colors.orangeAccent),
                                                      SizedBox(height: 5),
                                                      Text("Tidak ada jadwal saat ini", textAlign: TextAlign.center),
                                                    ],
                                                  )
                                                );
                                              }
                                              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                                key: ValueKey("$idKelas-$currentJamDocId-${controller.idTahunAjaran}"),
                                                stream: controller.getStreamJurnalDetail(idKelas, currentJamDocId),
                                                builder: (context, snapJurnalDetail) {
                                                  if (snapJurnalDetail.connectionState == ConnectionState.waiting) {
                                                    return Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, key: ValueKey("jurnalDetailLoader-$idKelas"))));
                                                  }
                                                  if (snapJurnalDetail.hasError) {
                                                    return Center(child: Text("Error: ${snapJurnalDetail.error}", style: TextStyle(color: Colors.red)));
                                                  }
                                                  if (!snapJurnalDetail.hasData || !snapJurnalDetail.data!.exists || snapJurnalDetail.data!.data() == null) {
                                                    return Center(
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(Icons.description_outlined, size: 30, color: Colors.blueGrey[300]),
                                                          SizedBox(height: 5),
                                                          Text("Jurnal belum diisi untuk jam ini", textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey[700])),
                                                        ],
                                                      )
                                                    );
                                                  }

                                                  var dataJurnalMap = snapJurnalDetail.data!.data()!;
                                                  return Container(
                                                    padding: EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.teal[50], // Warna latar detail jurnal
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisAlignment: MainAxisAlignment.center, // Pusatkan konten
                                                      children: [
                                                        Text("Jam: ${dataJurnalMap['jampelajaran'] ?? 'N/A'}", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                                        SizedBox(height: 4),
                                                        Text("Materi: ${dataJurnalMap['materipelajaran'] ?? 'Belum ada materi'}", style: TextStyle(fontSize: 14), maxLines: 3, overflow: TextOverflow.ellipsis),
                                                        // Tambahkan field lain jika ada, misal:
                                                        // if (dataJurnalMap['keterangan'] != null && dataJurnalMap['keterangan'].isNotEmpty)
                                                        //   Padding(
                                                        //     padding: const EdgeInsets.only(top: 4.0),
                                                        //     child: Text("Ket: ${dataJurnalMap['keterangan']}", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis,),
                                                        //   ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              );
                                            }),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            );
                          }),

                           SizedBox(height: 20),

                          ],
                        ),
                      ),
                    ],
                  ),

                  // JUDUL INFORMASI SEKOLAH (BAWAH)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Informasi Sekolah",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        TextButton(
                          onPressed: () {
                            Get.snackbar(
                              "Info",
                              "Nanti akan muncul page berita lengkap",
                            );
                          },
                          child: Text("Selengkapnya"),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  

                   // INFORMASI SEKOLAH (BAWAH)
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: controller.getDataInfo(),
                    builder: (context, snapInfo) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.data == null ||
                          (snapshot.data != null &&
                              (snapshot.data!.data() == null ||
                                  (snapshot.data!.data() as Map).isEmpty))) {
                        return Center(child: Text('Belum ada informasi'));
                      } else if (snapInfo.hasData) {
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: snapInfo.data!.docs.length,
                          itemBuilder: (context, index) {
                            var dataInfo = snapInfo.data!.docs[index].data();
                            var tanggalInputString =
                                dataInfo['tanggalinput'] as String?;
                            String formattedDate = "Tanggal tidak valid";

                            if (tanggalInputString != null &&
                                tanggalInputString.isNotEmpty) {
                              try {
                                // 1. Parse string dari Firestore ke DateTime object
                                DateTime dateTime = DateTime.parse(
                                  tanggalInputString,
                                );

                                // 2. Format DateTime object ke string yang diinginkan
                                // 'dd' untuk hari, 'MMMM' untuk nama bulan lengkap, 'yyyy' untuk tahun
                                // 'HH' untuk jam (00-23), 'mm' untuk menit
                                // Locale 'en_US' digunakan untuk memastikan nama bulan dalam bahasa Inggris ("May")
                                // Jika Anda ingin nama bulan dalam Bahasa Indonesia ("Mei"), gunakan 'id_ID'
                                // dan pastikan Flutter di-setup untuk lokalisasi Indonesia.
                                // Untuk "May" seperti permintaan, 'en_US' atau null (default locale jika English) sudah cukup.

                                // formattedDate =
                                //     DateFormat(
                                //       'dd MMMM yyyy - HH:mm',
                                //       'en_US',
                                //     ).format(dateTime) +
                                //     " WIB";

                                formattedDate =
                                    "${DateFormat('dd MMMM yyyy - HH:mm', 'en_US').format(dateTime)} WIB";

                                // Alternatif jika ingin "WIB" langsung di format string (kurang fleksibel untuk i18n "WIB" itu sendiri):
                                // formattedDate = DateFormat("dd MMMM yyyy - HH:mm 'WIB'", 'en_US').format(dateTime);
                              } catch (e) {
                                print(
                                  "Error parsing date '$tanggalInputString': $e",
                                );
                                // Jika terjadi error parsing, tampilkan string asli atau pesan error
                                formattedDate = tanggalInputString ?? "Format tanggal salah";
                              }
                            }

                            return InkWell(
                              onTap: () {
                                Get.toNamed(
                                  Routes.TAMPILKAN_INFO_SEKOLAH,
                                  arguments: dataInfo,
                                );
                              },
                              child: Container(
                                // margin: EdgeInsets.fromLTRB(15, 0, 15, 15),
                                margin: EdgeInsets.fromLTRB(
                                  15,
                                  (index == 0 ? 15 : 0),
                                  15,
                                  15,
                                ),
                                // Beri margin atas untuk item pertama
                                padding: EdgeInsets.all(10),

                                // height: 50,
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
                                  // color: Colors.brown,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.all(5),
                                      height: 75,
                                      width: 75,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        color: Colors.grey,
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            "https://picsum.photos/id/${index + 356}/500/500",
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            dataInfo['judulinformasi'],
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            // "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla eget placerat ipsum. Quisque sed metus elit. Phasellus viverra, magna tristique auctor volutpat, neque orci bibendum magna, vel varius augue felis quis ex.",
                                            dataInfo['informasisekolah'],
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),

                                          SizedBox(height: 20),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time_outlined,
                                                size: 12,
                                              ),
                                              SizedBox(width: 7),
                                              // Text(
                                              //   dataInfo['tanggalinput'],
                                              //   style: TextStyle(fontSize: 12),
                                              // ),
                                              Text(
                                                formattedDate, // <-- GUNAKAN VARIABEL YANG SUDAH DIFORMAT
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        // return Center(child: CircularProgressIndicator());
                        return Center(child: Text("Ada Kesalahan."));
                      }
                    },
                  ),
                ],
              ),
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
    required this.gambar,
    // required this.icon,
    required this.onTap,
  });

  final String title;
  // final Icon icon;
  final String gambar;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 10),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.all(7),
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                // child: Icon(icon.icon, size: 40, color: Colors.white),
                child: Image.asset(gambar, fit: BoxFit.contain),
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

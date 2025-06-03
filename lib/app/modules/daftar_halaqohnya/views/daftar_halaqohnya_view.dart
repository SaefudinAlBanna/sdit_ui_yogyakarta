import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../controllers/daftar_halaqohnya_controller.dart';

class DaftarHalaqohnyaView extends GetView<DaftarHalaqohnyaController> {
  DaftarHalaqohnyaView({super.key});

  final dataArgumen = Get.arguments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        shadowColor: Colors.red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        width: 230,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(15),
              height: 150,
              width: 230,
              color: Colors.grey,
              alignment: Alignment.bottomLeft,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Menu',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w300),
                ),
              ),
            ),
            ListTile(
              onTap: () {
                Get.back();
                Get.defaultDialog(
                  title: '${dataArgumen['fase']}',
                  content: SizedBox(
                    // height: 450,
                    // width: 350,
                    child: Column(
                      children: [
                        Column(
                          children: [
                            SizedBox(height: 5),
                            FutureBuilder<List<String>>(
                              future: controller.getDataKelasYangAda(),
                              builder: (context, snapshotkelas) {
                                // print('ini snapshotkelas = $snapshotkelas');
                                if (snapshotkelas.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                } else if (snapshotkelas.hasData) {
                                  List<String> kelasAjarGuru =
                                      snapshotkelas.data!;
                                  return SingleChildScrollView(
                                    child: Row(
                                      children:
                                          kelasAjarGuru.map((k) {
                                            return TextButton(
                                              onPressed: () {
                                                Get.back();
                                                controller.kelasSiswaC.text = k;
                                                Get.bottomSheet(
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 30,
                                                          vertical: 30,
                                                        ),
                                                    color: Colors.white,
                                                    child: Center(
                                                      child: StreamBuilder<
                                                        QuerySnapshot<
                                                          Map<String, dynamic>
                                                        >
                                                      >(
                                                        stream:
                                                            controller
                                                                .getDataSiswaStreamBaru(),
                                                        builder: (
                                                          context,
                                                          snapshotsiswa,
                                                        ) {
                                                          if (snapshotsiswa
                                                                  .connectionState ==
                                                              ConnectionState
                                                                  .waiting) {
                                                            return CircularProgressIndicator();
                                                          }
                                                          if (snapshotsiswa
                                                                  .data!
                                                                  .docs
                                                                  .isEmpty ||
                                                              snapshotsiswa
                                                                      .data ==
                                                                  null) {
                                                            return Center(
                                                              child: Text(
                                                                'Semua siswa sudah terpilih',
                                                              ),
                                                            );
                                                          }
                                                          if (snapshotsiswa
                                                              .hasData) {
                                                            return ListView.builder(
                                                              itemCount:
                                                                  snapshotsiswa
                                                                      .data!
                                                                      .docs
                                                                      .length,
                                                              itemBuilder: (
                                                                context,
                                                                index,
                                                              ) {
                                                                String
                                                                namaSiswa =
                                                                    snapshotsiswa
                                                                        .data!
                                                                        .docs[index]
                                                                        .data()['namasiswa'] ??
                                                                    'No Name';
                                                                String
                                                                nisnSiswa =
                                                                    snapshotsiswa
                                                                        .data!
                                                                        .docs[index]
                                                                        .data()['nisn'] ??
                                                                    'No NISN';
                                                                // ignore: prefer_is_empty
                                                                if (snapshotsiswa
                                                                            .data!
                                                                            .docs
                                                                            .length ==
                                                                        0 ||
                                                                    snapshotsiswa
                                                                        .data!
                                                                        .docs
                                                                        .isEmpty) {
                                                                  return Center(
                                                                    child: Text(
                                                                      'Semua siswa sudah terpilih',
                                                                    ),
                                                                  );
                                                                } else {
                                                                  return ListTile(
                                                                    onTap:
                                                                        () => controller.simpanSiswaKelompok(
                                                                          namaSiswa,
                                                                          nisnSiswa,
                                                                        ),
                                                                    title: Text(
                                                                      snapshotsiswa
                                                                          .data!
                                                                          .docs[index]
                                                                          .data()['namasiswa'],
                                                                    ),
                                                                    subtitle: Text(
                                                                      snapshotsiswa
                                                                          .data!
                                                                          .docs[index]
                                                                          .data()['namakelas'],
                                                                    ),
                                                                    leading: CircleAvatar(
                                                                      child: Text(
                                                                        snapshotsiswa
                                                                            .data!
                                                                            .docs[index]
                                                                            .data()['namasiswa'][0],
                                                                      ),
                                                                    ),
                                                                    trailing: Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: <
                                                                        Widget
                                                                      >[
                                                                        IconButton(
                                                                          tooltip:
                                                                              'Simpan',
                                                                          icon: const Icon(
                                                                            Icons.save,
                                                                          ),
                                                                          onPressed: () {
                                                                            controller.simpanSiswaKelompok(
                                                                              namaSiswa,
                                                                              nisnSiswa,
                                                                            );
                                                                          },
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                }
                                                              },
                                                            );
                                                          } else {
                                                            return Center(
                                                              child: Text(
                                                                'No data available',
                                                              ),
                                                            );
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Text(k),
                                            );
                                          }).toList(),
                                    ),
                                  );
                                } else {
                                  return SizedBox();
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              leading: Icon(Icons.person_add_sharp),
              title: Text('Tambah Siswa'),
            ),
            ListTile(
              onTap: () => Get.offAllNamed(Routes.HOME),
              title: Text("kembali"),
              // subtitle: t,
            ),

            ListTile(
              onTap: () {
                Get.defaultDialog(
                  onCancel: () {},
                  title: "Pilih kategori",
                  content: Column(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownSearch<String>(
                            decoratorProps: DropDownDecoratorProps(
                              decoration: InputDecoration(
                                labelText: "Kategori umi",
                                border: OutlineInputBorder(),
                                filled: true,
                              ),
                            ),
                            items:
                                (f, cs) =>
                                    Future.value(controller.getDataUmi()),
                            onChanged: (String? value) {
                              if (value != null) {
                                controller.umidrawerC.text = value;
                              }
                            },
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              fit: FlexFit.loose, // Coba loose atau tight
                              constraints: BoxConstraints(
                                maxHeight: 300,
                              ), // Batasi tinggi popup
                            ),
                          ),
                          SizedBox(height: 20),
                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                // ignore: unnecessary_null_comparison
                                if (controller.umidrawerC.text == null ||
                                    // ignore: unnecessary_null_comparison
                                    controller.umidrawerC.text.isEmpty) {
                                  Get.snackbar(
                                    'Peringatan',
                                    'Kategori umi belum dipilih',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                } else {
                                  Get.back();

                                  Get.bottomSheet(
                                    Container(
                                      color: Colors.white,
                                      // Bungkus dengan Container untuk memberi batasan tinggi
                                      constraints: BoxConstraints(
                                        maxHeight:
                                            Get.height *
                                            0.8, // Maks 80% tinggi layar
                                      ),
                                      child: StreamBuilder<
                                        QuerySnapshot<Map<String, dynamic>>
                                      >(
                                        stream:
                                            controller.getDaftarHalaqohDrawer(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          }
                                          if (snapshot.data == null ||
                                              snapshot.data!.docs.isEmpty) {
                                            return Center(
                                              child: Text(
                                                'Belum ada siswa atau semua siswa pada kategori ${controller.umidrawerC.text}',
                                              ),
                                            );
                                          }
                                          if (snapshot.hasData) {
                                            return ListView.builder(
                                              itemCount:
                                                  snapshot.data!.docs.length,
                                              // itemCount: 5,
                                              itemBuilder: (context, index) {
                                                var doc =
                                                    (snapshot.data
                                                            as QuerySnapshot)
                                                        .docs[index];
                                                return InkWell(
                                                  onTap: () {
                                                    controller.updateUmiDrawer(
                                                      doc.id,
                                                    );
                                                  },
                                                  child: Container(
                                                    height: 50,
                                                    margin: EdgeInsets.fromLTRB(
                                                      10,
                                                      5,
                                                      10,
                                                      7,
                                                    ),
                                                    padding: EdgeInsets.all(5),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            15,
                                                          ),
                                                      // color: Colors.green[200]
                                                      color: Colors.amber,
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          doc['namasiswa'] ??
                                                              'No Data',
                                                        ),
                                                        Text(
                                                          doc['kelas'] ??
                                                              'No Data',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          } else {
                                            return Center(
                                              child: Text('No data available'),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text("Pilih Siswa"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              leading: Icon(Icons.list_alt_outlined),
              title: Text("Tentukan Kategori"),
            ),

            ListTile(
              onTap:
                  () =>
                  // controller.test(),
                  Get.toNamed(Routes.DAFTAR_HALAQOH_PERFASE),
              leading: Icon(Icons.arrow_back_outlined),
              title: Text("Kembali"),
            ),
          ],
        ),
      ),

      appBar: AppBar(
        title: const Text('DaftarHalaqohnyaView'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: controller.getDataSiswaHalaqoh(),
        builder: (context, snapsiswahalaqoh) {
          if (snapsiswahalaqoh.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapsiswahalaqoh.data == null ||
              snapsiswahalaqoh.data!.docs.isEmpty) {
            return const Center(child: Text('Tidak ada data'));
          }
          if (snapsiswahalaqoh.hasData) {
            return ListView.builder(
              itemCount: snapsiswahalaqoh.data!.docs.length,
              itemBuilder: (context, index) {
                // print("lenght == ${snapsiswahalaqoh.data!.docs.length}"); // ya kriwel tidak dihitung
                var snapsiswa = snapsiswahalaqoh.data!.docs[index];
                return Material(
                  borderRadius: BorderRadius.circular(15),
                  child: InkWell(
                    onTap: () {
                      Get.defaultDialog(
                        onCancel: () => Get.back(),
                        onConfirm: () {
                          controller.updateUmi(snapsiswa.id);
                        },
                        title: "Kategori Umi",

                        content: Column(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownSearch<String>(
                                  decoratorProps: DropDownDecoratorProps(
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      prefixText: 'Umi : ',
                                    ),
                                  ),
                                  selectedItem: controller.umiC.text,
                                  items: (f, cs) => controller.getDataUmi(),
                                  onChanged: (String? value) {
                                    controller.umiC.text = value!;
                                  },
                                  popupProps: PopupProps.menu(
                                    // disabledItemFn: (item) => item == '1A', // contoh klo mau disable
                                    fit: FlexFit.tight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    snapsiswa['namasiswa'],
                                    style: TextStyle(fontSize: 15),
                                  ),
                                  Text(snapsiswa['kelas']),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      Get.toNamed(
                                        Routes.DAFTAR_NILAI,
                                        arguments: snapsiswa,
                                      );
                                    },
                                    icon: Icon(Icons.add_box_outlined),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.rocket_outlined),
                                    onPressed: () async {
                                      if (controller.isLoading.isFalse) {
                                        String nisnSiswa = snapsiswa['nisn'];
                                        await Get.defaultDialog(
                                          barrierDismissible: false,
                                          title: '${snapsiswa['fase']}',
                                          content: SizedBox(
                                            height: 350,
                                            width: 400,
                                            child: Column(
                                              children: [
                                                Column(
                                                  children: [
                                                    SizedBox(height: 20),
                                                    DropdownSearch<String>(
                                                      decoratorProps:
                                                          DropDownDecoratorProps(
                                                            decoration:
                                                                InputDecoration(
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                  filled: true,
                                                                  labelText:
                                                                      'Pengampu',
                                                                ),
                                                          ),
                                                      selectedItem:
                                                          controller
                                                                  .pengampuC
                                                                  .text
                                                                  .isNotEmpty
                                                              ? controller
                                                                  .pengampuC
                                                                  .text
                                                              : null,
                                                      items:
                                                          (f, cs) =>
                                                              controller
                                                                  .getDataPengampuFase(),
                                                      onChanged: (
                                                        String? value,
                                                      ) {
                                                        if (value != null) {
                                                          controller
                                                              .pengampuC
                                                              .text = value;
                                                        }
                                                      },
                                                      popupProps:
                                                          PopupProps.menu(
                                                            fit: FlexFit.tight,
                                                          ),
                                                    ),
                                                    SizedBox(height: 20),
                                                    TextField(
                                                      controller:
                                                          controller.alasanC,
                                                      decoration: InputDecoration(
                                                        border:
                                                            OutlineInputBorder(),
                                                        hintText:
                                                            'Alasan Pindah',
                                                      ),
                                                    ),
                                                    SizedBox(height: 20),
                                                    Column(
                                                      children: [
                                                        Obx(
                                                          () => ElevatedButton(
                                                            onPressed: () async {
                                                              if (controller
                                                                  .isLoading
                                                                  .isFalse) {
                                                                await controller
                                                                    .pindahkan(
                                                                      nisnSiswa,
                                                                    );
                                                                controller
                                                                    .getDataSiswaHalaqoh();
                                                              }
                                                            },
                                                            child: Text(
                                                              controller
                                                                      .isLoading
                                                                      .isFalse
                                                                  ? "Pindah halaqoh"
                                                                  : "LOADING...",
                                                            ),
                                                            // child: Text("Pindah halaqoh"),
                                                          ),
                                                        ),
                                                        SizedBox(height: 20),
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            Get.back();
                                                          },
                                                          child: Text(
                                                            controller
                                                                    .isLoading
                                                                    .isFalse
                                                                ? "Batal"
                                                                : "LOADING...",
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      } else {
                                        Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('Tidak ada data'));
          }
        },
      ),
    );
  }
}

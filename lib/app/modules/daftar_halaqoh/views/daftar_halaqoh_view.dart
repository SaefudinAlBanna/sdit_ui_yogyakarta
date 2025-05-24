import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../controllers/daftar_halaqoh_controller.dart';

class DaftarHalaqohView extends GetView<DaftarHalaqohController> {
  DaftarHalaqohView({super.key});

  final data = Get.arguments;

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
                  title: '${data['fase']}',
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
                                                                            Icons.arrow_circle_right_outlined,
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
          ],
        ),
      ),

      appBar: AppBar(title: Text(data['namapengampu']), centerTitle: true),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: controller.getDaftarHalaqoh(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Belum ada siswa..'));
          }
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var doc = (snapshot.data as QuerySnapshot).docs[index];
                return ListTile(
                  onTap: () => Get.toNamed(Routes.DAFTAR_NILAI, arguments: doc),
                  leading: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(50),
                      image: DecorationImage(
                        image: NetworkImage(
                          "https://ui-avatars.com/api/?name=${doc['namasiswa']}",
                        ),
                      ),
                    ),
                  ),
                  title: Text(doc['namasiswa'] ?? 'No Data'),
                  subtitle: Text(doc['kelas'] ?? 'No Data'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // IconButton(
                      //   tooltip: 'Halaqoh',
                      //   icon: const Icon(Icons.yard_outlined),
                      //   onPressed: () {
                      //     Get.toNamed(Routes.DAFTAR_NILAI, arguments: doc);
                      //   },
                      // ),
                      IconButton(
                        tooltip: 'umi',
                        icon: const Icon(Icons.star_border_purple500),
                        onPressed: () {
                          // Get.toNamed(Routes.DAFTAR_NILAI, arguments: doc);
                          Get.defaultDialog(
                            onCancel: () => Get.back(),
                            onConfirm: () {
                              controller.updateUmi(doc.id);
                              // Get.snackbar("Print", doc.id);
                            },
                            title: "Umi / Al-Qur'an",
                            // middleText: 'Silahkan tambahkan kelas baru',
                            content: Column(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Masukan Umi / Al-Qur'an",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 10),
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
                                        print("umiC = $value");
                                      },
                                      popupProps: PopupProps.menu(
                                        // disabledItemFn: (item) => item == '1A',
                                        fit: FlexFit.tight,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'pindah',
                        icon: const Icon(Icons.change_circle_outlined),
                        onPressed: () async {
                          if (controller.isLoading.isFalse) {
                            String nisnSiswa = doc['nisn'];
                            await Get.defaultDialog(
                              barrierDismissible: false,
                              title: '${doc['fase']}',
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
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  filled: true,
                                                  labelText: 'Pengampu',
                                                ),
                                              ),
                                          selectedItem:
                                              controller
                                                      .pengampuC
                                                      .text
                                                      .isNotEmpty
                                                  ? controller.pengampuC.text
                                                  : null,
                                          items:
                                              (f, cs) =>
                                                  controller
                                                      .getDataPengampuFase(),
                                          onChanged: (String? value) {
                                            if (value != null) {
                                              controller.pengampuC.text = value;
                                            }
                                          },
                                          popupProps: PopupProps.menu(
                                            fit: FlexFit.tight,
                                          ),
                                        ),
                                        SizedBox(height: 20),
                                        TextField(
                                          controller: controller.alasanC,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(),
                                            hintText: 'Alasan Pindah',
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
                                                    await controller.pindahkan(
                                                      nisnSiswa,
                                                    );
                                                    // await controller.test(nisnSiswa);
                                                    controller
                                                        .getDaftarHalaqoh();
                                                    // controller.deleteUser(
                                                    //     doc['nisn']);
                                                  }
                                                },
                                                child: Text(
                                                  controller.isLoading.isFalse
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
                                                controller.isLoading.isFalse
                                                    ? "Batal"
                                                    : "LOADING...",
                                              ),
                                            ),
                                            // ElevatedButton(
                                            //     onPressed: () =>
                                            //         controller.test(nisnSiswa),
                                            //     child: Text('test')),
                                          ],
                                        ),
                                      ],
                                    ),
                                    // SizedBox(height: 20),
                                    // ElevatedButton(
                                    //     onPressed: () => Get.back(),
                                    //     child: Text('Batal')),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            Center(child: CircularProgressIndicator());
                          }
                        },
                      ),
                      // IconButton(
                      //   tooltip: 'hapus',
                      //   icon: const Icon(Icons.cancel_outlined),
                      //   onPressed: () {
                      //     controller.deleteUser(doc['nisn']);
                      //     controller.ubahStatusSiswa(
                      //         doc['nisn'], doc['kelas']);
                      //     controller.getDaftarHalaqoh();
                      //   },
                      // ),
                    ],
                  ),
                );
              },
            );
          } else {
            return Center(child: Text('No data available'));
          }
        },
      ),
    );
  }
}

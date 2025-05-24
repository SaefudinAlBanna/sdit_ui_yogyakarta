import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../controllers/tambah_kelompok_mengaji_controller.dart';

class TambahKelompokMengajiView
    extends GetView<TambahKelompokMengajiController> {
  const TambahKelompokMengajiView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('TambahKelompokMengajiView'),
      //   centerTitle: true,
      // ),
      body: ListView(
        children: [
          Column(
            children: [
              SafeArea(
                child: Stack(
                  fit: StackFit.passthrough,
                  children: [
                    Container(
                      height: 150,
                      width: Get.width,
                      decoration: BoxDecoration(
                        color: Colors.indigo[400],
                        // image: DecorationImage(
                        //   image: AssetImage("assets/images/profile.png"),
                        // ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: Column(
                          children: [
                            Text(
                              "Tambah Kelompok Halaqoh",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

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
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    Container(
                      margin: EdgeInsets.only(top: 80),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 10,
                            ),
                            margin: EdgeInsets.symmetric(horizontal: 25),
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
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                FieldTambahKelompok(
                                  controller: controller,
                                  controllerNya: controller.faseC,
                                  label: 'Fase',
                                  getOptions: () {
                                    return controller.getDataFase();
                                  },
                                ),
                                SizedBox(height: 10),
                                DropdownSearch<String>(
                                  decoratorProps: DropDownDecoratorProps(
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      labelText: 'Pengampu',
                                    ),
                                  ),
                                  selectedItem:
                                      controller.pengampuC.text.isNotEmpty
                                          ? controller.pengampuC.text
                                          : null,
                                  items:
                                      (f, cs) => controller.getDataPengampu(),
                                  onChanged: (String? value) {
                                    if (value != null) {
                                      controller.pengampuC.text = value;
                                    }
                                  },
                                  popupProps: PopupProps.menu(
                                    fit: FlexFit.tight,
                                  ),
                                ),
                                FieldTambahKelompok(
                                  controller: controller,
                                  controllerNya: controller.tempatC,
                                  label: 'Tempat',
                                  getOptions: () {
                                    return controller.getDataTempat();
                                  },
                                ),
                                // FieldTambahKelompok(
                                //   controller: controller,
                                //   controllerNya: controller.semesterC,
                                //   label: 'Semester',
                                //   getOptions: () {
                                //     return controller.getDataSemester();
                                //   },
                                // ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              ElevatedButton(
                onPressed: () {
                  if (controller.faseC.text.isEmpty) {
                    Get.snackbar('Peringatan', 'Fase kosong');
                  } else if (controller.pengampuC.text.isEmpty) {
                    Get.snackbar('Peringatan', 'Pengampu kosong');
                  } else if (controller.tempatC.text.isEmpty) {
                    Get.snackbar('Peringatan', 'Tempat kosong');
                  } 
                  // else if (controller.semesterC.text.isEmpty) {
                  //   Get.snackbar('Peringatan', 'Semester kosong');
                  // } 
                  else {
                    // controller.buatKelompok();
                    controller.testBuat();
                  }
                },
                child: Text('Buat Kelompok'),
              ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Get.offAllNamed(Routes.HOME);
                },
                child: Text('kembali'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FieldTambahKelompok extends StatelessWidget {
  const FieldTambahKelompok({
    super.key,
    required this.controller,
    required this.controllerNya,
    required this.label,
    required this.getOptions,
  });

  final TambahKelompokMengajiController controller;
  final TextEditingController controllerNya;
  final String label;
  final List<String> Function() getOptions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DropdownSearch<String>(
        decoratorProps: DropDownDecoratorProps(
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            filled: true,
            labelText: label,
          ),
        ),
        selectedItem: controllerNya.text.isNotEmpty ? controllerNya.text : null,
        items: (f, cs) => getOptions(),
        onChanged: (String? value) {
          if (value != null) {
            controllerNya.text = value;
          }
        },
        popupProps: PopupProps.menu(fit: FlexFit.tight),
      ),
    );
  }
}

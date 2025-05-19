import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/tambah_siswa_controller.dart';

class TambahSiswaView extends GetView<TambahSiswaController> {
  const TambahSiswaView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('TambahSiswaView'),
      //   centerTitle: true,
      // ),
      body: ListView(
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
                    child: Text(
                      "Tambah Pegawai",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                Container(
                  margin: EdgeInsets.only(top: 50),
                  // width: Get.width,
                  child: Column(
                    children: [
                      Column(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 10,
                            ),
                            margin: EdgeInsets.symmetric(horizontal: 25),
                            // height: 140,
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
                              // borderRadius: BorderRadius.only(
                              //   topLeft: Radius.circular(20),
                              //   topRight: Radius.circular(20),
                              // ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                 FieldTambahSiswa(
                                  controller: controller,
                                  controllerNya: controller.nisnC,
                                  label: 'NISN',
                                ),
                                FieldTambahSiswa(
                                  controller: controller,
                                  controllerNya: controller.namaC,
                                  label: 'Nama',
                                ),
                                // Row(
                                //   children: [
                                //     Obx(
                                //       () => Radio(
                                //         value: "Ustadz",
                                //         groupValue:
                                //             controller.aliasNama.value,
                                //         activeColor: Colors.black,
                                //         fillColor: WidgetStateProperty.all(
                                //           Colors.grey[700],
                                //         ),
                                //         onChanged: (value) {
                                //           // Handle the change here
                                //           controller.aliasNama.value =
                                //               value.toString();
                                //           // print(value);
                                //         },
                                //       ),
                                //     ),
                                //     Text("Ustadz"),
                                //     SizedBox(width: 20),
                                //     Obx(
                                //       () => Radio(
                                //         value: "Ustadzah",
                                //         groupValue:
                                //             controller.jenisKelamin.value,
                                //         activeColor: Colors.black,
                                //         fillColor: WidgetStateProperty.all(
                                //           Colors.grey[700],
                                //         ),
                                //         onChanged: (value) {
                                //           // Handle the change here
                                //           controller.jenisKelamin.value =
                                //               value.toString();
                                //           // print(value);
                                //         },
                                //       ),
                                //     ),
                                //     Text("Ustadzah"),
                                //   ],
                                // ),
                                FieldTambahSiswa(
                                  controller: controller,
                                  controllerNya: controller.emailC,
                                  label: 'Email',
                                ),
                                Row(
                                  children: [
                                    Obx(
                                      () => Radio(
                                        value: "Laki-Laki",
                                        groupValue:
                                            controller.jenisKelamin.value,
                                        activeColor: Colors.black,
                                        fillColor: WidgetStateProperty.all(
                                          Colors.grey[700],
                                        ),
                                        onChanged: (value) {
                                          // Handle the change here
                                          controller.jenisKelamin.value =
                                              value.toString();
                                          // print(value);
                                        },
                                      ),
                                    ),
                                    Text("Laki-Laki"),
                                    SizedBox(width: 20),
                                    Obx(
                                      () => Radio(
                                        value: "Perempuan",
                                        groupValue:
                                            controller.jenisKelamin.value,
                                        activeColor: Colors.black,
                                        fillColor: WidgetStateProperty.all(
                                          Colors.grey[700],
                                        ),
                                        onChanged: (value) {
                                          // Handle the change here
                                          controller.jenisKelamin.value =
                                              value.toString();
                                          // print(value);
                                        },
                                      ),
                                    ),
                                    Text("Perempuan"),
                                  ],
                                ),

                                // DropdownSearch<String>(
                                //   decoratorProps: DropDownDecoratorProps(
                                //     decoration: InputDecoration(
                                      
                                //       border: OutlineInputBorder(),
                                //       enabledBorder: OutlineInputBorder(
                                //         borderSide: BorderSide(
                                //           color: Colors.grey,
                                //         ),
                                //       ),
                                //       filled: true,
                                //       labelText: 'Jabatan',
                                //       labelStyle: TextStyle(fontSize: 12),
                                //     ),
                                //   ),
                                //   selectedItem:
                                //       controller.jabatanC.text.isNotEmpty
                                //           ? controller.jabatanC.text
                                //           : null,
                                //   items: (f, cs) => controller.getDataJabatan(),
                                //   onChanged: (String? value) {
                                //     if (value != null) {
                                //       controller.jabatanC.text = value;
                                //     }
                                //   },
                                //   popupProps: PopupProps.menu(
                                //     fit: FlexFit.tight,
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(onPressed: (){
              if(controller.nisnC.text.isEmpty){
                Get.snackbar("Error", "NISN masih kosong");
              }
              else if(controller.namaC.text.isEmpty){
                Get.snackbar("Error", "nama masih kosong");
              }
              else if(controller.emailC.text.isEmpty){
                Get.snackbar("Error", "email masih kosong");
              }
              else if(controller.jenisKelamin.value.isEmpty){
                Get.snackbar("Error", "jenisKelamin masih kosong");
              }
              // else if(controller.jabatanC.text.isEmpty){
              //   Get.snackbar("Error", "jabatan masih kosong");
              // } 
              else {
                controller.tambahSiswa();
              }
            }, child: Text("Simpan")),
          ),
        ],
      ),
    );
  }
}

class FieldTambahSiswa extends StatelessWidget {
  const FieldTambahSiswa({
    super.key,
    required this.controller,
    required this.controllerNya,
    required this.label,
  });

  final TambahSiswaController controller;
  final TextEditingController controllerNya;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 10),
      child: TextField(
        controller: controllerNya,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 12),
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

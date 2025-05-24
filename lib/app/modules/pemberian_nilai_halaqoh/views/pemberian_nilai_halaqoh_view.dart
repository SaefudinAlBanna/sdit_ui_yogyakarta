import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../controllers/pemberian_nilai_halaqoh_controller.dart';

class PemberianNilaiHalaqohView
    extends GetView<PemberianNilaiHalaqohController> {
  PemberianNilaiHalaqohView({super.key});

  final dataxx = Get.arguments;

  @override
  Widget build(BuildContext context) {
    // print("dataxx = $dataxx");
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(15),
          children: [
            Column(children: [_buildHeaderSection()]),
            Divider(height: 3, color: Colors.black),
            SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Card(
                        child: Column(
                          spacing: 5,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nama Siswa : ${dataxx['namasiswa']}'),
                            Text('No Induk : ${dataxx['nisn']}'),
                            Text('Kelas :  ${dataxx['kelas']}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 20),
                  Column(
                    children: [
                      Card(
                        child: Column(
                          spacing: 5,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<Object>(
                              future: controller.ambilDataUmi(),
                              builder: (context, snapumi) {
                                if (snapumi.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (snapumi.data == null ||
                                    snapumi.data == "0") {
                                  return Text("Belum di input");
                                }
                                if (snapumi.hasData) {
                                  String dataUmi = snapumi.data as String;
                                  return Text("UMI : $dataUmi");
                                } else {
                                  return Text("Belum di input");
                                }
                              },
                            ),
                            Text("Ustadz/ah : ${dataxx['namapengampu']}"),
                            Text("Tempat : ${dataxx['tempatmengaji']}"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Column(
              spacing: 5,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text('Tatap muka ke :'),
                Text(
                  'Tanggal :   ${DateFormat.yMd().format(DateTime.now()).replaceAll("/", "-")}',
                ),
                SizedBox(height: 10),
                Text(
                  'HAFALAN',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Divider(height: 2, color: Colors.black),
                DropdownSearch<String>(
                  decoratorProps: DropDownDecoratorProps(
                    decoration: InputDecoration(
                      border: UnderlineInputBorder(),
                      filled: true,
                      prefixText: 'surat: ',
                    ),
                  ),
                  selectedItem: controller.suratC.text,
                  items:
                      (f, cs) => [
                        "Annas",
                        'Al-Falaq',
                        'Al Ikhlas',
                        'Al Lahab',
                        'An Nasr',
                        'dll',
                      ],
                  onChanged: (String? value) {
                    if (value != null) {
                      controller.suratC.text = value;
                    }
                  },
                  popupProps: PopupProps.menu(
                    // disabledItemFn: (item) => item == '1A',
                    fit: FlexFit.tight,
                  ),
                ),
                TextField(
                  controller: controller.ayatHafalC,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Ayat yang dihafal',
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'UMMI/ALQURAN',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Divider(height: 2, color: Colors.black),
                TextField(
                  controller: controller.halAyatC,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Hal / Ayat',
                  ),
                ),
                TextField(
                  controller: controller.materiC,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Materi',
                  ),
                ),
                TextField(
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  controller: controller.nilaiC,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Nilai (Hanya angka)',
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      int nilai = int.parse(value);
                      if (nilai > 100) {
                        controller.nilaiC.text = '100';
                        //Batasi nilai menjadi 100
                        controller
                            .nilaiC
                            .selection = TextSelection.fromPosition(
                          TextPosition(offset: controller.nilaiC.text.length),
                        );
                        // Pindahkan kursor ke akhir
                      } else if (nilai.toString().length > 3) {
                        controller.nilaiC.text = '100';
                        //Batasi nilai menjadi 100
                        controller
                            .nilaiC
                            .selection = TextSelection.fromPosition(
                          TextPosition(offset: controller.nilaiC.text.length),
                        );
                        // Pindahkan kursor ke akhir
                      }
                    }
                  },
                ),
                SizedBox(height: 10),

                Text(
                  'KETERANGAN / CATATAN PENGAMPU',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Divider(height: 2, color: Colors.black),
                SizedBox(height: 3),
                // TextField(
                //   controller: controller.keteranganGuruC,
                //   decoration: InputDecoration(
                //     border: OutlineInputBorder(),
                //     hintText: 'Keterangan / Catatan Pengampu',
                //   ),
                // ),
                Row(
                  children: [
                    Obx(
                      () => Radio(
                        value:
                            "Alhamdulillah, ananda hari sangat bagus dan lancar, dalam memahami materi hari ini, InsyaAlloh, besok lanjut ke materi selanjutnta.. Barokallohu fiik.",
                        groupValue: controller.keteranganHalaqoh.value,
                        activeColor: Colors.black,
                        fillColor: WidgetStateProperty.all(Colors.grey[700]),
                        onChanged: (value) {
                          // Handle the change here
                          controller.keteranganHalaqoh.value = value.toString();
                          // print(value);
                        },
                      ),
                    ),
                    Text("Lanjut"),
                    SizedBox(width: 20),
                    Obx(
                      () => Radio(
                        value:
                            "Alhamdulillah, ananda hari sangat bagus dan lancar, tetap semangat ya sholih.. Barokallohu fiik..",
                        groupValue: controller.keteranganHalaqoh.value,
                        activeColor: Colors.black,
                        fillColor: WidgetStateProperty.all(Colors.grey[700]),
                        onChanged: (value) {
                          // Handle the change here
                          controller.keteranganHalaqoh.value = value.toString();
                          // print(value);
                        },
                      ),
                    ),
                    Text("Lancar"),
                    SizedBox(width: 20),
                    Obx(
                      () => Radio(
                        value:
                            "Alhamdulillah Ananda hari ini sudah ada peningkatan, akan tetapi mohon nanti dirumah dipelajari lagi, dan nanti akan kita ulangi lagi untuk materi ini",
                        groupValue: controller.keteranganHalaqoh.value,
                        activeColor: Colors.black,
                        fillColor: WidgetStateProperty.all(Colors.grey[700]),
                        onChanged: (value) {
                          // Handle the change here
                          controller.keteranganHalaqoh.value = value.toString();
                          // print(value);
                        },
                      ),
                    ),
                    Text("Ulang"),
                  ],
                ),
                Center(
                  child: FloatingActionButton(
                    onPressed: () {
                      if (controller.suratC.text.isEmpty) {
                        Get.snackbar(
                          'Peringatan',
                          'Hafalan surat masih kosong',
                        );
                      } else if (controller.ayatHafalC.text.isEmpty) {
                        Get.snackbar(
                          'Peringatan',
                          'Ayat hafalan surat masih kosong',
                        );
                      }
                      // else if (controller.jldSuratC.text.isEmpty) {
                      //   Get.snackbar(
                      //     'Peringatan',
                      //     'Jilid / AlQuran ummi masih kosong',
                      //   );
                      // }
                      else if (controller.halAyatC.text.isEmpty) {
                        Get.snackbar(
                          'Peringatan',
                          'Halaman atau Ayat masih kosong',
                        );
                      } else if (controller.materiC.text.isEmpty) {
                        Get.snackbar('Peringatan', 'Materi masih kosong');
                      } else if (controller.nilaiC.text.isEmpty) {
                        Get.snackbar('Peringatan', 'Nilai masih kosong');
                      } else if (controller.keteranganHalaqoh.value.isEmpty) {
                        Get.snackbar('Peringatan', 'Keterangan masih kosong');
                      } else {
                        controller.simpanNilai();
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text('Simpan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Kartu Prestasi'),
      backgroundColor: Colors.indigo[400],
      elevation: 0,
    );
  }

  Widget _buildHeaderSection() {
    return Column(children: [_buildHeader(), const SizedBox(height: 5)]);
  }

  Widget _buildHeader() {
    return Column(
      children: const [
        Text(
          "KARTU PRESTASI PEMBELAJARAN ALQUR'AN METODE UMMI",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 5),
        Text(
          "SD IT UKHUWAH ISLAMIYYAH",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

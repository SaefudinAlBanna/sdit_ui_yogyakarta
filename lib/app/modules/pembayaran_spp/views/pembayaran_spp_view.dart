import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/pembayaran_spp_controller.dart';

class PembayaranSppView extends GetView<PembayaranSppController> {
  PembayaranSppView({super.key});

  final dataArgumen = Get.arguments;

  @override
  Widget build(BuildContext context) {
    // Panggil onInit secara eksplisit jika controller tidak diinisialisasi oleh Get.put() di tempat lain
    // Namun, biasanya GetView sudah menangani ini jika controller di-inject dengan benar.
    // Jika idTahunAjaran masih null, Anda mungkin perlu memastikan onInit controller dipanggil.
    // Contoh: WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (controller.idTahunAjaran == null) {
    //     controller.onInit(); // Atau panggil method spesifik untuk load tahun ajaran
    //   }
    // });

    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Siswa Kelas $dataArgumen'),
        centerTitle: true,
      ),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: controller.getDataSiswa(),
        builder: (context, snapsiswa) {
          if (snapsiswa.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapsiswa.hasError) {
            // Tambahkan penanganan error
            return Center(child: Text("Error: ${snapsiswa.error}"));
          }
          if (snapsiswa.data == null || snapsiswa.data!.docs.isEmpty) {
            // print("snapsiswa.lenght = ${snapsiswa.data?.docs.length ?? 0}"); // Handle null
            return Center(
              child: Text(
                "Siswa tidak ada di kelas ini atau data tahun ajaran belum siap.",
              ),
            );
          }
          // if (snapsiswa.hasData) {
          var datasiswaList = snapsiswa.data!.docs;
          return ListView(
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text("wali kelas : ${datasiswaList[0]['walikelas']}"),
              ),
              SizedBox(height: 25),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: snapsiswa.data!.docs.length,
                itemBuilder: (context, index) {
                  var datasiswa = datasiswaList[index].data();
                  String idsiswa =
                      datasiswaList[index].id; // NISN adalah ID dokumen siswa
                  String namaSiswa = datasiswa['namasiswa'] ?? 'Tanpa Nama';
                  return InkWell(
                    onTap: () {
                      controller
                          .clearForm(); // Bersihkan form setiap kali dialog utama dibuka
                      // var data = snapsiswa.data!.docs[index];
                      // String idsiswa = data['nisn'];
                      Get.defaultDialog(
                        onCancel: () {
                          controller.clearForm();
                        },
                        title: 'Pilih Jenis Pembayaran',
                        content: Column(
                          children: [
                            Column(
                              // crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DropdownSearch<String>(
                                  decoratorProps: DropDownDecoratorProps(
                                    decoration: InputDecoration(
                                      labelText: "Jenis Pembayaran",
                                      border: OutlineInputBorder(),
                                      filled: true,
                                    ),
                                  ),
                                  items:
                                      (f, cs) => Future.value(
                                        controller.getDataPembayaranList(),
                                      ),
                                  onChanged: (String? value) {
                                    if (value != null) {
                                      controller.pembayaranC.text = value;
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
                                      if (controller.pembayaranC.text == null ||
                                          // ignore: unnecessary_null_comparison
                                          controller.pembayaranC.text.isEmpty) {
                                        Get.snackbar(
                                          'Peringatan',
                                          'Jenis Pembayaran belum dipilih',
                                          snackPosition: SnackPosition.BOTTOM,
                                        );
                                      } else {
                                        Get.back();

                                        // ---------------------------
                                        Get.bottomSheet(
                                          Container(
                                            // Bungkus dengan Container untuk memberi batasan tinggi
                                            constraints: BoxConstraints(
                                              maxHeight:
                                                  Get.height *
                                                  0.8, // Maks 80% tinggi layar
                                            ),
                                            child: ListView(
                                              children: [
                                                Container(
                                                  height: Get.height,
                                                  width: Get.width,
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 20,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    // Tambah dekorasi
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.only(
                                                          topLeft:
                                                              Radius.circular(
                                                                20,
                                                              ),
                                                          topRight:
                                                              Radius.circular(
                                                                20,
                                                              ),
                                                        ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize
                                                            .min, // Agar BottomSheet tidak memenuhi layar
                                                    children: [
                                                      Center(
                                                        child: Text(
                                                          "Pembayaran ${controller.pembayaranC.text}",
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(height: 8),

                                                      Text(
                                                        "Nama Siswa: $namaSiswa",
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      Text(
                                                        "NISN: $idsiswa",
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              Colors.grey[700],
                                                        ),
                                                      ),
                                                      Text(
                                                        "Riwayat Pembayaran:",
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      SizedBox(height: 20),
                                                      StreamBuilder<
                                                        QuerySnapshot<
                                                          Map<String, dynamic>
                                                        >
                                                      >(
                                                        stream: controller
                                                            .getDataPembayaran(
                                                              idsiswa,
                                                            ),
                                                        builder: (
                                                          context,
                                                          snappembayaran,
                                                        ) {
                                                          if (snappembayaran
                                                                  .connectionState ==
                                                              ConnectionState
                                                                  .waiting) {
                                                            return Center(
                                                              child:
                                                                  CircularProgressIndicator(),
                                                            );
                                                          }
                                                          if (snappembayaran
                                                              .hasError) {
                                                            return Center(
                                                              child: Text(
                                                                "Error: ${snappembayaran.error}",
                                                              ),
                                                            );
                                                          }

                                                          bool
                                                          tidakAdaPembayaran =
                                                              snappembayaran
                                                                      .data ==
                                                                  null ||
                                                              snappembayaran
                                                                  .data!
                                                                  .docs
                                                                  .isEmpty;

                                                          if (tidakAdaPembayaran) {
                                                            // TAMPILKAN TOMBOL BAYAR JIKA BELUM ADA PEMBAYARAN
                                                            return Center(
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Text(
                                                                    "Siswa belum melakukan pembayaran ${controller.pembayaranC.text}.",
                                                                  ),
                                                                  SizedBox(
                                                                    height: 20,
                                                                  ),
                                                                  ElevatedButton(
                                                                    onPressed: () {
                                                                      // Bersihkan form detail sebelum menampilkan dialog
                                                                      controller
                                                                          .clearDetailPembayaranForm();

                                                                      Get.defaultDialog(
                                                                        title:
                                                                            "Input Pembayaran ${controller.pembayaranC.text}",
                                                                        onCancel: () {
                                                                          controller
                                                                              .clearDetailPembayaranForm(); // Bersihkan juga saat cancel
                                                                          Get.back();
                                                                        },
                                                                        content: Column(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            // KONDISI DI SINI
                                                                            if (controller.pembayaranC.text ==
                                                                                "SPP") ...[
                                                                              Text(
                                                                                "Pilih Bulan:",
                                                                                style: TextStyle(
                                                                                  fontWeight:
                                                                                      FontWeight.bold,
                                                                                ),
                                                                              ),
                                                                              SizedBox(
                                                                                height:
                                                                                    8,
                                                                              ),
                                                                              DropdownSearch<
                                                                                String
                                                                              >(
                                                                                // Ganti decoratorProps ke dropdownDecoratorProps
                                                                                decoratorProps: DropDownDecoratorProps(
                                                                                  decoration: InputDecoration(
                                                                                    // labelText: "Bulan", // Tidak perlu jika sudah ada prefixText
                                                                                    border:
                                                                                        OutlineInputBorder(),
                                                                                    filled:
                                                                                        true,
                                                                                    // prefixText: 'Bulan : ', // Atau gunakan labelText
                                                                                  ),
                                                                                ),
                                                                                // selectedItem: controller.bulanC.text.isEmpty ? null : controller.bulanC.text,
                                                                                popupProps: PopupProps.menu(
                                                                                  showSearchBox:
                                                                                      true,
                                                                                  fit:
                                                                                      FlexFit.loose,
                                                                                  constraints: BoxConstraints(
                                                                                    maxHeight:
                                                                                        250,
                                                                                  ),
                                                                                ),
                                                                                items:
                                                                                    (
                                                                                      f,
                                                                                      cs,
                                                                                    ) =>
                                                                                        controller.getListBulan(),
                                                                                onChanged: (
                                                                                  String? value,
                                                                                ) {
                                                                                  if (value !=
                                                                                      null) {
                                                                                    controller.bulanC.text = value;
                                                                                  }
                                                                                },
                                                                              ),
                                                                            ] else ...[
                                                                              Text(
                                                                                controller.pembayaranC.text ==
                                                                                            "Infaq" ||
                                                                                        controller.pembayaranC.text ==
                                                                                            "Lain-Lain"
                                                                                    ? "Nominal Pembayaran:"
                                                                                    : "Keterangan/Nominal:",
                                                                                style: TextStyle(
                                                                                  fontWeight:
                                                                                      FontWeight.bold,
                                                                                ),
                                                                              ),
                                                                              SizedBox(
                                                                                height:
                                                                                    8,
                                                                              ),
                                                                              TextField(
                                                                                controller:
                                                                                    controller.nominalAtauKeteranganC,
                                                                                decoration: InputDecoration(
                                                                                  border:
                                                                                      OutlineInputBorder(),
                                                                                  filled:
                                                                                      true,
                                                                                  hintText:
                                                                                      controller.pembayaranC.text ==
                                                                                                  "Infaq" ||
                                                                                              controller.pembayaranC.text ==
                                                                                                  "Lain-Lain"
                                                                                          ? "Masukkan nominal"
                                                                                          : "Contoh: Buku Paket Kls X / 150000",
                                                                                ),
                                                                                keyboardType:
                                                                                    controller.pembayaranC.text ==
                                                                                                "Infaq" ||
                                                                                            controller.pembayaranC.text ==
                                                                                                "Lain-Lain"
                                                                                        ? TextInputType.number
                                                                                        : TextInputType.text,
                                                                              ),
                                                                            ],
                                                                            SizedBox(
                                                                              height:
                                                                                  25,
                                                                            ),
                                                                            Center(
                                                                              child: ElevatedButton(
                                                                                onPressed: () {
                                                                                  // Panggil fungsi simpan dari controller
                                                                                  controller.simpanPembayaran(
                                                                                    idsiswa,
                                                                                    namaSiswa,
                                                                                  );
                                                                                },
                                                                                child: Text(
                                                                                  "Simpan Pembayaran",
                                                                                ),
                                                                                style: ElevatedButton.styleFrom(
                                                                                  padding: EdgeInsets.symmetric(
                                                                                    horizontal:
                                                                                        30,
                                                                                    vertical:
                                                                                        12,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      );
                                                                    },
                                                                    child: Text(
                                                                      "Bayar ${controller.pembayaranC.text}",
                                                                    ),
                                                                    style: ElevatedButton.styleFrom(
                                                                      padding: EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            30,
                                                                        vertical:
                                                                            12,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          } else {
                                                            // TAMPILKAN RIWAYAT PEMBAYARAN JIKA ADA
                                                            var dataPembayaran =
                                                                snappembayaran
                                                                    .data!
                                                                    .docs;
                                                            return Column(
                                                              children: [
                                                                ListView.builder(
                                                                  shrinkWrap:
                                                                      true,
                                                                  physics:
                                                                      NeverScrollableScrollPhysics(),
                                                                  itemCount:
                                                                      dataPembayaran
                                                                          .length,
                                                                  itemBuilder: (
                                                                    context,
                                                                    indexbayar,
                                                                  ) {
                                                                    var pembayaranItem =
                                                                        dataPembayaran[indexbayar]
                                                                            .data();
                                                                    String
                                                                    detailText =
                                                                        "";
                                                                    if (controller
                                                                            .pembayaranC
                                                                            .text ==
                                                                        "SPP") {
                                                                      detailText =
                                                                          "Bulan: ${pembayaranItem['bulan'] ?? '-'}";
                                                                    } else {
                                                                      detailText =
                                                                          "Detail: ${pembayaranItem['detail'] ?? (pembayaranItem['nominal']?.toString() ?? '-')}";
                                                                    }
                                                                    Timestamp?
                                                                    tglBayarTimestamp =
                                                                        pembayaranItem['tglbayar'];
                                                                    String
                                                                    tglBayarText =
                                                                        tglBayarTimestamp !=
                                                                                null
                                                                            ? "${tglBayarTimestamp.toDate().day}/${tglBayarTimestamp.toDate().month}/${tglBayarTimestamp.toDate().year}"
                                                                            : "Tanggal tidak ada";

                                                                    return Card(
                                                                      margin: EdgeInsets.symmetric(
                                                                        vertical:
                                                                            4,
                                                                      ),
                                                                      child: ListTile(
                                                                        title: Text(
                                                                          detailText,
                                                                        ),
                                                                        subtitle:
                                                                            Text(
                                                                              "Tgl Bayar: $tglBayarText",
                                                                            ),
                                                                        trailing: Icon(
                                                                          Icons
                                                                              .check_circle,
                                                                          color:
                                                                              Colors.green,
                                                                        ),
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                                SizedBox(
                                                                  height: 20,
                                                                ),
                                                                // Tombol bayar lagi (jika jenis pembayaran memungkinkan pembayaran berulang selain SPP)
                                                                if (controller
                                                                        .pembayaranC
                                                                        .text !=
                                                                    "SPP") // Contoh: SPP hanya bisa bayar jika belum ada untuk bulan tsb
                                                                  ElevatedButton(
                                                                    onPressed: () {
                                                                      controller
                                                                          .clearDetailPembayaranForm();
                                                                      Get.defaultDialog(
                                                                        title:
                                                                            "Input Pembayaran ${controller.pembayaranC.text}",
                                                                        onCancel: () {
                                                                          controller
                                                                              .clearDetailPembayaranForm();
                                                                          Get.back();
                                                                        },
                                                                        content: Column(
                                                                          /* ... Konten form input sama seperti di atas ... */
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            // KONDISI DI SINI (sama seperti blok if di atas)
                                                                            if (controller.pembayaranC.text ==
                                                                                "SPP") ...[
                                                                              // Seharusnya tidak sampai sini jika SPP dan sudah ada pembayaran,
                                                                              // kecuali Anda ingin mengizinkan pembayaran SPP lagi.
                                                                              // Untuk SPP, biasanya dicek apakah bulan tertentu sudah dibayar.
                                                                              Text(
                                                                                "Pilih Bulan:",
                                                                                style: TextStyle(
                                                                                  fontWeight:
                                                                                      FontWeight.bold,
                                                                                ),
                                                                              ),
                                                                              SizedBox(
                                                                                height:
                                                                                    8,
                                                                              ),
                                                                              DropdownSearch<
                                                                                String
                                                                              >(
                                                                                decoratorProps: DropDownDecoratorProps(
                                                                                  decoration: InputDecoration(
                                                                                    border:
                                                                                        OutlineInputBorder(),
                                                                                    filled:
                                                                                        true,
                                                                                  ),
                                                                                ),
                                                                                popupProps: PopupProps.menu(
                                                                                  showSearchBox:
                                                                                      true,
                                                                                  fit:
                                                                                      FlexFit.loose,
                                                                                  constraints: BoxConstraints(
                                                                                    maxHeight:
                                                                                        250,
                                                                                  ),
                                                                                ),
                                                                                items:
                                                                                    (
                                                                                      f,
                                                                                      cs,
                                                                                    ) =>
                                                                                        controller
                                                                                            .getListBulan()
                                                                                            .where(
                                                                                              (
                                                                                                bulan,
                                                                                              ) =>
                                                                                                  !dataPembayaran.any(
                                                                                                    (
                                                                                                      pb,
                                                                                                    ) =>
                                                                                                        pb.data()['bulan'] ==
                                                                                                        bulan,
                                                                                                  ),
                                                                                            )
                                                                                            .toList(), // Hanya bulan yang belum dibayar
                                                                                onChanged: (
                                                                                  String? value,
                                                                                ) {
                                                                                  if (value !=
                                                                                      null)
                                                                                    controller.bulanC.text = value;
                                                                                },
                                                                              ),
                                                                            ] else ...[
                                                                              Text(
                                                                                controller.pembayaranC.text ==
                                                                                            "Infaq" ||
                                                                                        controller.pembayaranC.text ==
                                                                                            "Lain-Lain"
                                                                                    ? "Nominal Pembayaran:"
                                                                                    : "Keterangan/Nominal:",
                                                                                style: TextStyle(
                                                                                  fontWeight:
                                                                                      FontWeight.bold,
                                                                                ),
                                                                              ),
                                                                              SizedBox(
                                                                                height:
                                                                                    8,
                                                                              ),
                                                                              TextField(
                                                                                controller:
                                                                                    controller.nominalAtauKeteranganC,
                                                                                decoration: InputDecoration(
                                                                                  border:
                                                                                      OutlineInputBorder(),
                                                                                  filled:
                                                                                      true,
                                                                                  hintText:
                                                                                      controller.pembayaranC.text ==
                                                                                                  "Infaq" ||
                                                                                              controller.pembayaranC.text ==
                                                                                                  "Lain-Lain"
                                                                                          ? "Masukkan nominal"
                                                                                          : "Contoh: Buku Paket Kls X / 150000",
                                                                                ),
                                                                                keyboardType:
                                                                                    controller.pembayaranC.text ==
                                                                                                "Infaq" ||
                                                                                            controller.pembayaranC.text ==
                                                                                                "Lain-Lain"
                                                                                        ? TextInputType.number
                                                                                        : TextInputType.text,
                                                                              ),
                                                                            ],
                                                                            SizedBox(
                                                                              height:
                                                                                  25,
                                                                            ),
                                                                            Center(
                                                                              child: ElevatedButton(
                                                                                onPressed:
                                                                                    () => controller.simpanPembayaran(
                                                                                      idsiswa,
                                                                                      namaSiswa,
                                                                                    ),
                                                                                child: Text(
                                                                                  "Simpan Pembayaran",
                                                                                ),
                                                                                style: ElevatedButton.styleFrom(
                                                                                  padding: EdgeInsets.symmetric(
                                                                                    horizontal:
                                                                                        30,
                                                                                    vertical:
                                                                                        12,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      );
                                                                    },
                                                                    child: Text(
                                                                      "Bayar Lagi ${controller.pembayaranC.text}",
                                                                    ),
                                                                    style: ElevatedButton.styleFrom(
                                                                      padding: EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            30,
                                                                        vertical:
                                                                            12,
                                                                      ),
                                                                    ),
                                                                  ),
                                                              ],
                                                            );
                                                          }
                                                          // return SizedBox.shrink(); // Fallback jika tidak ada kondisi terpenuhi
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          isScrollControlled:
                                              true, // Penting untuk bottom sheet dengan konten dinamis/panjang
                                          backgroundColor:
                                              Colors
                                                  .transparent, // Agar rounded corner container terlihat
                                          // ignorePersistentDynamicLinkConfig: true, // bila perlu
                                        );
                                        // controller.clearForm(); // Pindahkan clearForm ke onCancel atau setelah aksi selesai
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 40,
                                        vertical: 15,
                                      ),
                                      textStyle: TextStyle(fontSize: 16),
                                    ),
                                    child: Text(
                                      'Lanjutkan',
                                    ), // Ganti teks tombol
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.fromLTRB(15, 0, 15, 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16), // Perbesar padding
                        child: Text(namaSiswa, style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
          // } else { // Kondisi ini tidak akan tercapai jika alur di atas benar
          //   return Center(
          //     child: Text("Tidak dapat memuat data, periksa koneksi internet"),
          //   );
          // }
        },
      ),
    );
  }
}

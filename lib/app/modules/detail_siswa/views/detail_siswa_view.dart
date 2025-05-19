import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/detail_siswa_controller.dart';

class DetailSiswaView extends GetView<DetailSiswaController> {
   DetailSiswaView({super.key});

  final String dataNama = Get.arguments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: controller.getDetailSiswa(),
          builder: (context, snapshotDetail) {
            if (snapshotDetail.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshotDetail.hasData) {
              final data = snapshotDetail.data!.docs.first.data();
              String tglLahir;
              try {
                tglLahir = DateFormat('dd MMMM, yyyy').format(
                  DateFormat('EEEE, dd MMMM, yyyy').parse(data['tanggalLahir']),
                );
              } catch (e) {
                tglLahir = '-'; // Fallback value
                // print('Error parsing date: $e');
              }
              return SafeArea(
                child: Column(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(50),
                              image: DecorationImage(
                                  image: NetworkImage(
                                      "https://ui-avatars.com/api/?name=${data['nama']}")),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(data['nama']),
                      ],
                    ),
                    Expanded(
                      child: SafeArea(
                        child: ListView(
                          children: [
                            Container(
                              margin: EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 15),
                              // height: Get.height,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // InfoDetailSiswa(icon: Icon(Icons.airline_seat_recline_normal_rounded)),
                                    InfoDetailSiswa(
                                        data: data,
                                        icon:
                                            data['jenisKelamin'] == "Perempuan"
                                                ? Icon(Icons.woman)
                                                : Icon(Icons.man),
                                        isi: 'jenisKelamin'.isNotEmpty
                                            ? "jenisKelamin"
                                            : "-"),
                                    InfoDetailSiswa(
                                        data: data,
                                        icon: Icon(Icons.camera_front_rounded),
                                        isi: 'nisn'.isNotEmpty ? "nisn" : "-"),
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(Icons.cake),
                                        SizedBox(width: 10),
                                        Text(tglLahir.isNotEmpty
                                            ? tglLahir
                                            : "-"),
                                      ],
                                    ),
                                    InfoDetailSiswa(
                                        data: data,
                                        icon: Icon(Icons.mosque),
                                        isi:
                                            'agama'.isNotEmpty ? 'agama' : "-"),
                                    InfoDetailSiswa(
                                        data: data,
                                        icon: Icon(Icons.home),
                                        isi: 'alamat'),
                                    InfoDetailSiswa(
                                        data: data,
                                        icon: Icon(Icons.phone_android),
                                        // ignore: unnecessary_null_comparison, prefer_if_null_operators
                                        isi: 'noHpOrangTua' != null
                                            ? 'noHpOrangTua'
                                            : 'noHpWali'),
                                    InfoDetailSiswa(
                                        data: data,
                                        icon: Icon(Icons.wc),
                                        isi: 'namaIbu'.isNotEmpty
                                            ? 'namaIbu'
                                            : "-"),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              );
            } else {
              return Text('Terjadi kesalahan');
            }
          }),
    );
  }
}

class InfoDetailSiswa extends StatelessWidget {
  const InfoDetailSiswa({
    super.key,
    required this.data,
    required this.icon,
    required this.isi,
  });

  final Map<String, dynamic> data;
  final Icon icon;
  final String isi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          icon,
          SizedBox(width: 10),
          Text(data[isi]),
        ],
      ),
    );
  }
}

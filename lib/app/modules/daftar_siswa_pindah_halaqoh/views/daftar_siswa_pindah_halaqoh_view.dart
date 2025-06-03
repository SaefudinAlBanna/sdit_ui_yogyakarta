import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/daftar_siswa_pindah_halaqoh_controller.dart';

class DaftarSiswaPindahHalaqohView
    extends GetView<DaftarSiswaPindahHalaqohController> {
  const DaftarSiswaPindahHalaqohView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Siswa Pindah Halaqoh'),
        centerTitle: true,
      ),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: controller.dataSiswaPindah(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } if (snapshot.data!.docs.isEmpty || snapshot.data == null) {
              return Center(child: Text('Tidak ada siswa pindah halaqoh'));
            
            } if(snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final datanya = snapshot.data!.docs[index].data();
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      // mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("nama siswa : ${datanya.isNotEmpty
                            ? (datanya['namasiswa'] ?? 'No Data')
                            : '-'}"),

                            Text(datanya.isNotEmpty
                                ? (datanya['tanggalpindah'] != null
                                    ? DateFormat("dd-MM-yyyy").format(DateTime.parse(datanya['tanggalpindah'] as String))
                                    : 'No Data')
                                : 'No Data'),
                          ],
                        ),
                        SizedBox(height: 3),
                        Text("kelas : ${datanya.isNotEmpty
                            ? (datanya['kelas'] ?? 'No Data')
                            : '-'}"),
                        SizedBox(height: 3),
                        Text("Fase : ${datanya.isNotEmpty
                            ? (datanya['fase_baru'] ?? 'No Data')
                            : '-'}"),
                        
                        SizedBox(height: 3),
                        Text("Halaqoh lama : ${datanya.isNotEmpty
                            ? (datanya['pengampu_lama'] ?? 'No Data')
                            : '-'}"),
                        SizedBox(height: 3),
                        Text("Halaqoh baru : ${datanya.isNotEmpty
                            ? (datanya['pengampu_baru'] ?? 'No Data')
                            : '-'}"),
                        SizedBox(height: 3),
                        Text("alasan pindah : ${datanya.isNotEmpty
                            ? (datanya['alasanpindah'] ?? 'No Data')
                            : '-'}"),
                      ],
                    ),
                  );
                },
              );
          } else {
            return Center(
              child: Text('No data available'),
            );
          }
        }),
    );
  }
}

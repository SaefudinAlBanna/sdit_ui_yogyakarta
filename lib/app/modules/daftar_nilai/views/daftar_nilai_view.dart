import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/daftar_nilai_controller.dart';

class DaftarNilaiView extends GetView<DaftarNilaiController> {
   DaftarNilaiView({super.key});

  final dataxx = Get.arguments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // appBar: _buildAppBar(),
        appBar: AppBar(
          title: Text('Daftar Nilai Siswa'),
          centerTitle: true,
        ),
        body: SafeArea(
            child: Column(
          children: [
            Column(
              children: [
                Center(
                    child: Container(
                  margin: EdgeInsets.only(top: 30, bottom: 10),
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(40),
                    image: DecorationImage(
                        image: NetworkImage(
                            "https://ui-avatars.com/api/?name=${dataxx['namasiswa']}"),
                        fit: BoxFit.cover),
                  ),
                )),
                Text(dataxx['namasiswa']),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
                child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    future: controller.getDataNilai(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.data!.docs.isEmpty ||
                          snapshot.data == null) {
                        return Center(child: Text('Belum ada data nilai'));
                      }
                      if (snapshot.hasData) {
                        return ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final data = snapshot.data!.docs[index].data();
                            return Container(
                              margin: EdgeInsets.only(
                                  bottom: 10, left: 10, right: 10),
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.grey[300],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Tanggal : ${DateFormat.yMMMEd().format(DateTime.parse(data['tanggalinput']))}'),
                                  SizedBox(height: 7),
                                  Divider(
                                    height: 2,
                                    color: Colors.black,
                                  ),
                                  SizedBox(height: 7),
                                  Text(
                                      'Hafalan Surat : ${data['hafalansurat']}'),
                                  SizedBox(height: 7),
                                  Text(
                                      'UMMI Jld/ Surat : ${data['ummijilidatausurat']}'),
                                  SizedBox(height: 7),
                                  Text('Materi : ${data['materi']}'),
                                  SizedBox(height: 7),
                                  Text('Nilai : ${data['nilai']}'),
                                  SizedBox(height: 15),
                                  Text(
                                    'Catatan',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Divider(),
                                  // SizedBox(height: 3),
                                  Text(
                                      'pengampu : ${data['keteranganpengampu']}'),
                                  SizedBox(height: 7),
                                  // Text('orangtua : ${data['keteranganorangtua']}'),
                                  // Text( "orangtua : ${data == 0 ? (data['keteranganorangtua'] ?? '-') : '-'}"),
                                  if (data['keteranganorangtua'] != "0")
                                        Text('orangtua : ${data['keteranganorangtua']}') 
                                  else Text("orangtua : -")
                                ],
                              ),
                            );
                          },
                        );
                      } else {
                        return Center(child: Text('No data available'));
                      }
                    })),
          ],
        )));
  }
}

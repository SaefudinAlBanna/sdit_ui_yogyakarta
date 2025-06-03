import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/tampilkan_info_sekolah_controller.dart';



class TampilkanInfoSekolahView extends GetView<TampilkanInfoSekolahController> {
   TampilkanInfoSekolahView({super.key});

  final dataArgument = Get.arguments;

  @override
  Widget build(BuildContext context) {
    print("dataArgument =$dataArgument");
    return Scaffold(
      appBar: AppBar(
        title: const Text('TampilkanInfoSekolahView'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.all(10),
            child: Text(
              "Penginput : ${dataArgument['namapenginput']}",
              style: TextStyle(fontSize: 13),
              ),
          ),
          Container(
            margin: EdgeInsets.all(10),
            // padding: EdgeInsets.all(50),
            child: Text(
              dataArgument['informasisekolah'],
              // ,
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

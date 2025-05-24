import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/mapel_siswa_controller.dart';

class MapelSiswaView extends GetView<MapelSiswaController> {
   MapelSiswaView({super.key});

   final argumenData = Get.arguments;

  @override
  Widget build(BuildContext context) {
    print("argumenData = $argumenData");
    return Scaffold(
      appBar: AppBar(
        title: const Text('MapelSiswaView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'MapelSiswaView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

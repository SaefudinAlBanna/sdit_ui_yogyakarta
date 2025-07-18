import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/rapor_siswa_controller.dart';

class RaporSiswaView extends GetView<RaporSiswaController> {
  const RaporSiswaView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RaporSiswaView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'RaporSiswaView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

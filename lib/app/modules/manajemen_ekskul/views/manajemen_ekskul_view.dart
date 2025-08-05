import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/manajemen_ekskul_controller.dart';

class ManajemenEkskulView extends GetView<ManajemenEkskulController> {
  const ManajemenEkskulView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ManajemenEkskulView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'ManajemenEkskulView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

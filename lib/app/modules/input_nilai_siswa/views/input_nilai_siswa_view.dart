import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/input_nilai_siswa_controller.dart';

class InputNilaiSiswaView extends GetView<InputNilaiSiswaController> {
  const InputNilaiSiswaView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InputNilaiSiswaView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'InputNilaiSiswaView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

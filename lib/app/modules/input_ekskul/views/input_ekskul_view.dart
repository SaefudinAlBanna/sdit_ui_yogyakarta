import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/input_ekskul_controller.dart';

class InputEkskulView extends GetView<InputEkskulController> {
  const InputEkskulView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Ekskul Siswa'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoSiswa(),
              const SizedBox(height: 24),
              const Text(
                "Pilih Ekstrakurikuler",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              const SizedBox(height: 8),
              _buildPilihanEkskul(),
            ],
          ),
        );
      }),
      // bottomNavigationBar: _buildSimpanButton(),
    );
  }

  Widget _buildInfoSiswa() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.teal, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.dataSiswa['namasiswa'] ?? 'Nama Siswa',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Kelas: ${controller.idKelas} | ID: ${controller.idSiswa}",
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPilihanEkskul() {
    return Obx(() => Wrap(
      spacing: 12.0,
      runSpacing: 12.0,
      children: controller.masterEkskul.map((namaEkskul) {
        // Gunakan .value agar Obx tahu harus rebuild saat list berubah
        final isSelected = controller.ekskulTerpilih.value.contains(namaEkskul);
        return FilterChip(
          label: Text(namaEkskul),
          selected: isSelected,
          onSelected: (selected) {
            controller.toggleEkskul(namaEkskul);
          },
          selectedColor: Colors.teal,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87
          ),
        );
      }).toList(),
    ));
  }
  
  // Widget _buildSimpanButton() {
  //   // Kode ini tidak berubah
  //   return Padding(
  //     padding: const EdgeInsets.fromLTRB(16,0,16,24), // penyesuaian padding
  //     child: Obx(() => ElevatedButton.icon(
  //         onPressed: controller.isSaving.value ? null : () => controller.simpanPerubahan(),
  //         icon: controller.isSaving.value
  //             ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
  //             : const Icon(Icons.save),
  //         label: Text(controller.isSaving.value ? 'Menyimpan...' : 'Simpan Perubahan'),
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: Colors.teal,
  //           foregroundColor: Colors.white,
  //           padding: const EdgeInsets.symmetric(vertical: 16),
  //           textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/spesialisasi_controller.dart';

class SpesialisasiView extends GetView<SpesialisasiController> {
  const SpesialisasiView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Spesialisasi'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarSpesialisasi.isEmpty) {
          return const Center(child: Text('Belum ada data spesialisasi.'));
        }
        return ListView.builder(
          itemCount: controller.daftarSpesialisasi.length,
          itemBuilder: (context, index) {
            final spesialisasi = controller.daftarSpesialisasi[index];
            return ListTile(
              title: Text(spesialisasi.namaSpesialisasi),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showFormDialog(isUpdate: true, id: spesialisasi.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(spesialisasi.id),
                  ),
                ],
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFormDialog({bool isUpdate = false, String? id}) {
    final controller = Get.find<SpesialisasiController>();
    if (isUpdate && id != null) {
      // Isi textfield dengan nama yang ada jika ini adalah mode update
      final spesialisasi = controller.daftarSpesialisasi.firstWhere((s) => s.id == id);
      controller.namaC.text = spesialisasi.namaSpesialisasi;
    } else {
      controller.namaC.clear();
    }
    
    Get.defaultDialog(
      title: isUpdate ? 'Edit Spesialisasi' : 'Tambah Spesialisasi',
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: controller.namaC,
          decoration: const InputDecoration(labelText: 'Nama Spesialisasi'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (isUpdate) {
              controller.updateSpesialisasi(id!, controller.namaC.text);
            } else {
              controller.addSpesialisasi();
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(String id) {
    Get.defaultDialog(
      title: 'Konfirmasi Hapus',
      middleText: 'Apakah Anda yakin ingin menghapus spesialisasi ini?',
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            Get.find<SpesialisasiController>().deleteSpesialisasi(id);
            Get.back();
          },
          child: const Text('Hapus'),
        ),
      ],
    );
  }
}
// File: lib/app/modules/admin_manajemen/views/master_ekskul_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/master_ekskul_model.dart';
import '../controllers/master_ekskul_controller.dart';

class MasterEkskulView extends GetView<MasterEkskulController> {
  const MasterEkskulView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Ekstrakurikuler'),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.daftarMasterEkskul.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarMasterEkskul.isEmpty) {
          return const Center(child: Text('Belum ada data master ekskul.'));
        }
        return ListView.builder(
          itemCount: controller.daftarMasterEkskul.length,
          itemBuilder: (context, index) {
            final ekskul = controller.daftarMasterEkskul[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(ekskul.namaMaster),
                subtitle: Text("Kategori: ${ekskul.kategori}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showFormDialog(isUpdate: true, ekskul: ekskul),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(ekskul.id),
                    ),
                  ],
                ),
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

  void _showFormDialog({bool isUpdate = false, MasterEkskulModel? ekskul}) {
    if (isUpdate && ekskul != null) {
      controller.fillFormForEdit(ekskul);
    } else {
      controller.clearForm();
    }
    
    Get.defaultDialog(
      title: isUpdate ? 'Edit Master Ekskul' : 'Tambah Master Ekskul',
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Agar tidak overflow jika keyboard muncul
          child: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: controller.namaC,
                  decoration: const InputDecoration(labelText: 'Nama Ekskul (cth: Pramuka)'),
                ),
                TextFormField(
                  controller: controller.kategoriC,
                  decoration: const InputDecoration(labelText: 'Kategori (cth: Olahraga, Seni)'),
                ),
                TextFormField(
                  controller: controller.deskripsiC,
                  decoration: const InputDecoration(labelText: 'Deskripsi Default (Opsional)'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () { Get.back(); controller.clearForm(); }, child: const Text('Batal')),
        ElevatedButton(
          onPressed: () {
            if (isUpdate && ekskul != null) {
              controller.updateMasterEkskul(ekskul.id);
            } else {
              controller.addMasterEkskul();
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
      middleText: 'Apakah Anda yakin ingin menghapus master ekskul ini?',
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            controller.deleteMasterEkskul(id);
            Get.back();
          },
          child: const Text('Hapus'),
        ),
      ],
    );
  }
}
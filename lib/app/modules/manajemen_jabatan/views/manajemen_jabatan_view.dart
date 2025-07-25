// lib/app/modules/manajemen_jabatan/views/manajemen_jabatan_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/manajemen_jabatan_controller.dart';

class ManajemenJabatanView extends GetView<ManajemenJabatanController> {
  const ManajemenJabatanView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Get.put(ManajemenJabatanController());

    return Scaffold(
      appBar: AppBar(title: Text('Manajemen Jabatan')),
      body: Obx(() {
        if (controller.isLoading.isTrue) return Center(child: CircularProgressIndicator());
        if (controller.daftarJabatan.isEmpty) return Center(child: Text('Belum ada data jabatan.'));

        return ListView.builder(
          itemCount: controller.daftarJabatan.length,
          itemBuilder: (context, index) {
            final doc = controller.daftarJabatan[index];
            final namaJabatan = (doc.data() as Map<String, dynamic>)['nama'] ?? 'Tanpa Nama';

            return ListTile(
              title: Text(namaJabatan),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: Icon(Icons.edit, color: Colors.amber.shade700), onPressed: () => controller.showFormDialog(docId: doc.id, namaAwal: namaJabatan)),
                IconButton(icon: Icon(Icons.delete, color: Colors.red.shade700), onPressed: () => controller.hapusJabatan(doc.id, namaJabatan)),
              ]),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(onPressed: () => controller.showFormDialog(), child: Icon(Icons.add)),
    );
  }
}
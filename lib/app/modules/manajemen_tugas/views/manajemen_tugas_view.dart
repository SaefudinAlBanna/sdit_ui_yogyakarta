// lib/app/modules/manajemen_jabatan/views/manajemen_jabatan_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/manajemen_tugas_controller.dart';

class ManajemenTugasView extends GetView<ManajemenTugasController> {
  const ManajemenTugasView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Get.put(ManajemenTugasController());

    return Scaffold(
      appBar: AppBar(title: Text('Manajemen Tugas')),
      body: Obx(() {
        if (controller.isLoading.isTrue) return Center(child: CircularProgressIndicator());
        if (controller.daftarTugas.isEmpty) return Center(child: Text('Belum ada data Tugas.'));

        return ListView.builder(
          itemCount: controller.daftarTugas.length,
          itemBuilder: (context, index) {
            final doc = controller.daftarTugas[index];
            final namaTugas = (doc.data() as Map<String, dynamic>)['nama'] ?? 'Tanpa Nama';

            return ListTile(
              title: Text(namaTugas),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: Icon(Icons.edit, color: Colors.amber.shade700), onPressed: () => controller.showFormDialog(docId: doc.id, namaAwal: namaTugas)),
                IconButton(icon: Icon(Icons.delete, color: Colors.red.shade700), onPressed: () => controller.hapusTugas(doc.id, namaTugas)),
              ]),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(onPressed: () => controller.showFormDialog(), child: Icon(Icons.add)),
    );
  }
}
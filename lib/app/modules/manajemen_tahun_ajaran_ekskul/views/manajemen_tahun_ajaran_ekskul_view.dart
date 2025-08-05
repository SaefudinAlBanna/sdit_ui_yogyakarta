import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/manajemen_tahun_ajaran_ekskul_controller.dart';

class ManajemenTahunAjaranEkskulView extends GetView<ManajemenTahunAjaranEkskulController> {
  const ManajemenTahunAjaranEkskulView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Utilitas Tahun Ajaran"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Duplikasi Data Ekstrakurikuler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text("Gunakan fitur ini di akhir tahun ajaran untuk menyalin semua data ekskul ke tahun ajaran berikutnya."),
                    const Divider(height: 32),
                    Obx(() => ListTile(
                      leading: const Icon(Icons.folder_copy_outlined),
                      title: const Text("Tahun Ajaran Sumber"),
                      subtitle: Text(controller.tahunAjaranSumber.value, style: const TextStyle(fontWeight: FontWeight.bold)),
                    )),
                    Obx(() => ListTile(
                      leading: const Icon(Icons.drive_file_move_outline),
                      title: const Text("Tahun Ajaran Tujuan"),
                      subtitle: Text(controller.tahunAjaranTujuan.value, style: const TextStyle(fontWeight: FontWeight.bold)),
                    )),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: Obx(() => ElevatedButton.icon(
                        icon: controller.isLoading.value 
                            ? const SizedBox.shrink() 
                            : const Icon(Icons.copy_all_rounded),
                        label: Text(controller.isLoading.value ? 'Menyalin Data...' : 'Salin Data Ekskul'),
                        onPressed: controller.isLoading.value || !controller.isReadyForCopy.value
                            ? null
                            : () => _showCopyConfirmation(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      )),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCopyConfirmation() {
    Get.defaultDialog(
      title: "Konfirmasi Penyalinan",
      middleText: "Anda akan menyalin semua data ekskul dari tahun ${controller.tahunAjaranSumber.value} ke ${controller.tahunAjaranTujuan.value}.\n\nAnggota, pengumuman, dan catatan tidak akan disalin.\n\nProses ini tidak dapat dibatalkan. Lanjutkan?",
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
        ElevatedButton(
          onPressed: () {
            Get.back();
            controller.salinDataEkskul();
          },
          child: const Text("Ya, Lanjutkan"),
        ),
      ],
    );
  }
}
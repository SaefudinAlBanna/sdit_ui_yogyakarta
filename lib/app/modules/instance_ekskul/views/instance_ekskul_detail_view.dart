// File: lib/app/modules/admin_manajemen/views/instance_ekskul_detail_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/instance_ekskul_model.dart';
import '../controllers/instance_ekskul_controller.dart';
import 'kelola_anggota_view.dart';

class InstanceEkskulDetailView extends GetView<InstanceEkskulController> {
  final InstanceEkskulModel instance;
  
  const InstanceEkskulDetailView({super.key, required this.instance});

  @override
  Widget build(BuildContext context) {
    final masterInfo = controller.opsiMasterEkskul.firstWhereOrNull((m) => m.id == instance.masterEkskulRef);

    return Scaffold(
      appBar: AppBar(
        title: Text(masterInfo?.namaMaster ?? 'Detail Ekskul'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              instance.namaTampilan,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Divider(),
            
            const Text(
              "Manajemen Anggota",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("Kelola siswa yang terdaftar dalam ekstrakurikuler ini."),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: Obx(() {
                final bool isLoading = controller.isLoadingSiswa.value;
                return ElevatedButton.icon(
                  icon: isLoading
                      ? Container(
                          width: 20, height: 20,
                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.groups),
                  label: Text(isLoading ? 'Mempersiapkan Data...' : 'Kelola Keanggotaan'),
                  
                  // --- PERUBAHAN UTAMA DI SINI ---
                  // onPressed sekarang hanya memanggil satu fungsi
                  onPressed: isLoading
                      ? null
                      : () => controller.navigateToKelolaAnggota(instance.id),
                  
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    disabledBackgroundColor: Colors.grey.shade400,
                    disabledForegroundColor: Colors.white,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// Hapus import yang tidak digunakan secara langsung di file ini jika ada
// import '../../../routes/app_pages.dart';
import '../controllers/instance_ekskul_controller.dart';
import 'instance_ekskul_detail_view.dart';
import 'instance_ekskul_form_view.dart';
// import 'kelola_anggota_view.dart'; // Tidak dipanggil langsung dari sini

class InstanceEkskulView extends GetView<InstanceEkskulController> {
  const InstanceEkskulView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Ekstrakurikuler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat Ulang Data',
            onPressed: () => controller.fetchAllData(),
          ),
          // Hapus atau biarkan komentar jika Anda masih ingin referensi
          // IconButton(onPressed: (){...}, icon: Icon(Icons.zoom_out_map_rounded)),
          // IconButton(onPressed: () async {...}, icon: Icon(Icons.person_2_outlined))
        ],
      ),
      
      body: Obx(() {
        if (controller.isLoading.value && controller.daftarInstanceEkskul.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarInstanceEkskul.isEmpty) {
          return const Center(child: Text('Belum ada ekskul yang dibuka untuk tahun ajaran ini.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: controller.daftarInstanceEkskul.length,
          itemBuilder: (context, index) {
            final instance = controller.daftarInstanceEkskul[index];
            final masterInfo = controller.opsiMasterEkskul.firstWhereOrNull((m) => m.id == instance.masterEkskulRef);
            
            return Card(
              elevation: 2,
              child: ListTile(
                title: Text(
                  "${masterInfo?.namaMaster ?? 'Ekskul Dihapus'} - ${instance.namaTampilan}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    // Menampilkan nama-nama pembina
                    Text(
                      "Pembina: ${instance.pembina.map((p) => p['nama']).join(', ')}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(
                        "${instance.hariJadwal}, ${instance.jamMulai} - ${instance.jamSelesai}",
                        style: const TextStyle(fontSize: 12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // --- NAVIGASI YANG BENAR SESUAI ALUR KITA ---
                  // Saat item di-tap, kita selalu ke halaman detail sebagai "hub" utama.
                  Get.to(() => InstanceEkskulDetailView(instance: instance));
                },
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.clearForm();
          // Mengarah ke form kosong untuk membuat ekskul baru
          Get.to(() => const InstanceEkskulFormView());
        },
        child: const Icon(Icons.add),
        tooltip: 'Buka Ekskul Baru',
      ),
    );
  }
}
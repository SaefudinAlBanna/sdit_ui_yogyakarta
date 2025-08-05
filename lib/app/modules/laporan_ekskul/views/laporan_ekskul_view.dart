import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/laporan_ekskul_controller.dart';

class LaporanEkskulView extends GetView<LaporanEkskulController> {
  const LaporanEkskulView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Laporan Statistik Ekskul"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.generateLaporan(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarLaporan.isEmpty) {
          return const Center(child: Text("Tidak ada data ekskul untuk dilaporkan."));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: controller.daftarLaporan.length,
          itemBuilder: (context, index) {
            final laporan = controller.daftarLaporan[index];
            return Card(
              child: ListTile(
                onTap: () {
                  controller.openDetailLaporan(laporan);
                },
                leading: CircleAvatar(
                  child: Text(
                    "${index + 1}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  laporan.namaEkskulLengkap,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Pembina: ${laporan.namaPembina.join(', ')}"),
                trailing: Chip(
                  label: Text(
                    "${laporan.jumlahAnggota} Anggota",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.blue,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
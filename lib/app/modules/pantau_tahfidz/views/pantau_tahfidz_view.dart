// lib/app/modules/pantau_tahfidz/views/pantau_tahfidz_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/pantau_tahfidz_controller.dart';

class PantauTahfidzView extends GetView<PantauTahfidzController> {
  const PantauTahfidzView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pemantauan Tahfidz"),
        actions: [
          Obx(() => controller.kelasTerpilih.value != null
              ? IconButton(icon: const Icon(Icons.print), tooltip: "Cetak Laporan Kelas", onPressed: () => controller.showCetakLaporanKelasDialog())
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.daftarKelas.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClassChips(),
            const Divider(),
            Expanded(
              child: Obx(() {
                if (controller.kelasTerpilih.value == null) {
                  return const Center(child: Text("Silakan pilih kelas di atas untuk melihat data."));
                }
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildClassDetail();
              }),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildClassChips() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Pilih Kelas:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.daftarKelas.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final kelas = controller.daftarKelas[index];
                return Obx(() {
                  final bool isSelected = controller.kelasTerpilih.value?['id'] == kelas['id'];
                  return ChoiceChip(
                    label: Text(kelas['namakelas']),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) controller.pilihKelas(kelas);
                    },
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassDetail() {
    final kelas = controller.kelasTerpilih.value!;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        ListTile(title: const Text("Wali Kelas"), subtitle: Text(kelas['walikelas'] ?? '-')),
        const Text("Guru Pendamping:", style: TextStyle(fontWeight: FontWeight.bold)),
        ...controller.daftarPendamping.entries.map((p) => ListTile(dense: true, title: Text("- ${p.value}"))).toList(),
        if (controller.daftarPendamping.isEmpty) const ListTile(dense: true, title: Text("- Tidak ada")),
        const Divider(),
        const Text("Daftar Siswa:", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...controller.daftarSiswa.map((siswa) => _buildSiswaExpansionTile(siswa)),
      ],
    );
  }

  Widget _buildSiswaExpansionTile(Map<String, dynamic> siswa) {
    final nisn = siswa['id'];
    final namaSiswa = siswa['namasiswa'];
    return ExpansionTile(
      title: Text(namaSiswa),
      children: [
        // Widget riwayat penilaian siswa (read-only)
        // ... (Mirip dengan _buildHistorySection dari KelasTahfidzView, tapi tanpa tombol edit/delete)
        // Anda juga bisa menambahkan tombol cetak individu di sini.
      ],
    );
  }
}
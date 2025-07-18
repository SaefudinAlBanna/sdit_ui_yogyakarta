// lib/app/modules/laksanakan_ujian/views/laksanakan_ujian_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/siswa_ujian.dart';
import '../controllers/laksanakan_ujian_controller.dart';

class LaksanakanUjianView extends GetView<LaksanakanUjianController> {
  const LaksanakanUjianView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daftar Peserta Ujian")),
      body: StreamBuilder<List<SiswaUjian>>(
        stream: controller.getSiswaSiapUjian(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error: ${snapshot.error}");
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Tidak ada siswa yang siap ujian saat ini."));
          }

          final daftarSiswaUjian = snapshot.data!;
          return ListView.builder(
            itemCount: daftarSiswaUjian.length,
            itemBuilder: (context, index) {
              final siswa = daftarSiswaUjian[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(siswa.namaSiswa, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Ujian Level: ${siswa.levelUjian}\nCapaian: ${siswa.capaian}"),
                  isThreeLine: true,
                  trailing: const Icon(Icons.gavel_rounded),
                  onTap: () => _showPenilaianDialog(context, siswa),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showPenilaianDialog(BuildContext context, SiswaUjian siswa) {
    controller.catatanPengujiC.clear();
    Get.defaultDialog(
      title: "Penilaian Ujian",
      content: Column(
        children: [
          Text(siswa.namaSiswa, style: Get.textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: controller.catatanPengujiC,
            decoration: const InputDecoration(labelText: 'Catatan Penguji (Opsional)'),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => controller.prosesHasilUjian(siswa, false),
          child: const Text("Tidak Lulus"),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
        ),
        ElevatedButton(
          onPressed: () => controller.prosesHasilUjian(siswa, true),
          child: const Text("Lulus"),
        ),
      ],
    );
  }
}
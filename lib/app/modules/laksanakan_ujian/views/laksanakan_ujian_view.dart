// lib/app/modules/laksanakan_ujian/views/laksanakan_ujian_view.dart
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/siswa_ujian.dart';
import '../../daftar_halaqohnya/controllers/daftar_halaqohnya_controller.dart';
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
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'nilai') _showPenilaianDialog(context, siswa);
                      if (value == 'batal') controller.batalkanKesiapanUjian(siswa); // Panggil fungsi baru
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'nilai', child: Text('Beri Nilai Ujian')),
                      const PopupMenuItem(value: 'batal', child: Text('Batalkan Kesiapan', style: TextStyle(color: Colors.red))),
                    ],
                  ),
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
    controller.nilaiUjianC.clear();
    final theme = Theme.of(context);

    Get.defaultDialog(
      title: "Penilaian Ujian",
      titleStyle: theme.textTheme.headlineSmall,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      content: Column(
        children: [
          // [PERBAIKAN] Tampilkan namaSiswa
          Text(siswa.namaSiswa, style: theme.textTheme.titleLarge),
          const SizedBox(height: 20),
          TextField(
            controller: controller.nilaiUjianC,
            decoration: const InputDecoration(labelText: 'Nilai Ujian (0-100)', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller.catatanPengujiC,
            decoration: const InputDecoration(labelText: 'Evaluasi Ujian (Opsional)', border: OutlineInputBorder()),
            maxLines: 4, // <-- Perbesar area catatan
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          // Jika tidak lulus, langsung panggil proses
          onPressed: () => controller.prosesHasilUjian(siswa, false),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
          child: const Text("Tidak Lulus"),
        ),
        ElevatedButton(
          // Jika lulus, TUTUP dialog ini dan BUKA dialog selanjutnya
          onPressed: () {
            Get.back(); // Tutup dialog penilaian
            _showUpdateUmiDialog(context, siswa); // Buka dialog update UMI
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
          child: const Text("Lulus"),
        ),
      ],
    );
  }

  void _showUpdateUmiDialog(BuildContext context, SiswaUjian siswa) {
    controller.umiBaruC.clear();
    final theme = Theme.of(context);

    Get.defaultDialog(
      title: "Promosi Kenaikan Level",
      content: Column(
        children: [
          Text("Pilih level UMI baru untuk:", style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(siswa.namaSiswa, style: theme.textTheme.titleLarge),
          const SizedBox(height: 20),
          DropdownSearch<String>(
            popupProps: const PopupProps.menu(showSearchBox: true),
            // Ambil daftar level dari controller koordinator atau pengampu
            // items:(f, cs)=> Get.find<DaftarHalaqohnyaController>().listLevelUmi,
            items: (f, cs) => controller.listLevelUmi,
            onChanged: (value) => controller.umiBaruC.text = value ?? '',
            decoratorProps: const DropDownDecoratorProps(
              decoration: InputDecoration(
                labelText: "Level UMI Baru",
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
      confirm: Obx(() => ElevatedButton(
        onPressed: controller.isDialogLoading.value 
          ? null 
          : () {
              // Panggil proses dengan isLulus: true dan level UMI baru
              controller.prosesHasilUjian(siswa, true, levelUmiBaru: controller.umiBaruC.text);
            },
        child: controller.isDialogLoading.value
            ? const CircularProgressIndicator()
            : const Text("Simpan & Selesaikan"),
      )),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }
}
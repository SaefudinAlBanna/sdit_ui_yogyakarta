// lib/app/modules/buat_jadwal_pelajaran/views/buat_jadwal_pelajaran_view.dart

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/buat_jadwal_pelajaran_controller.dart';

class BuatJadwalPelajaranView extends GetView<BuatJadwalPelajaranController> {
  const BuatJadwalPelajaranView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor Jadwal Pelajaran'),
        actions: [
          Obx(() => controller.isLoading.value || controller.isLoadingJadwal.value
              ? const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
              : IconButton(icon: const Icon(Icons.save), tooltip: "Simpan Jadwal", onPressed: controller.simpanJadwalKeFirestore)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Obx(() {
              if (controller.isLoading.value && controller.daftarKelas.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return DropdownButtonFormField<String>(
                value: controller.selectedKelasId.value,
                hint: const Text('Pilih Kelas Terlebih Dahulu'),
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Kelas', border: OutlineInputBorder()),
                items: controller.daftarKelas.map((kelas) {
                  return DropdownMenuItem<String>(value: kelas['id'], child: Text(kelas['nama']));
                }).toList(),
                onChanged: controller.onKelasChanged,
              );
            }),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.selectedKelasId.value == null) {
                return const Expanded(child: Center(child: Text('Pilih kelas untuk memulai...', style: TextStyle(fontSize: 16, color: Colors.grey))));
              }
              if (controller.isLoadingJadwal.value) {
                return const Expanded(child: Center(child: CircularProgressIndicator()));
              }
              return Expanded(child: _buildScheduleEditor());
            }),
          ],
        ),
      ),
      floatingActionButton: Obx(() => controller.selectedKelasId.value != null && !controller.isLoadingJadwal.value
          ? FloatingActionButton(onPressed: controller.tambahPelajaran, tooltip: 'Tambah Slot Pelajaran', child: const Icon(Icons.add))
          : const SizedBox.shrink()),
    );
  }

  Widget _buildScheduleEditor() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: controller.selectedHari.value,
          decoration: const InputDecoration(labelText: 'Pilih Hari', border: OutlineInputBorder()),
          items: controller.daftarHari.map((String hari) => DropdownMenuItem<String>(value: hari, child: Text(hari))).toList(),
          onChanged: controller.changeSelectedHari,
        ),
        const SizedBox(height: 16),
      Expanded(
        child: Obx(() {
          final listPelajaran = controller.jadwalPelajaran[controller.selectedHari.value]!;
          if (listPelajaran.isEmpty) {
            return const Center(child: Text('Jadwal kosong. Klik + untuk menambah.'));
          }

          // [BARU] Urutkan daftar pelajaran sebelum ditampilkan
          listPelajaran.sort((a, b) {
            final jamA = a['jam'] as String?;
            final jamB = b['jam'] as String?;
            if (jamA == null) return 1; // Item tanpa jam ditaruh di akhir
            if (jamB == null) return -1;
            return jamA.compareTo(jamB); // Urutkan secara abjad (yang juga urutan waktu)
          });

          return ListView.builder(
            itemCount: listPelajaran.length,
            itemBuilder: (context, index) {
              final pelajaran = listPelajaran[index];
              return _buildPelajaranCard(pelajaran, index);
            },
          );
        }),
      ),
    ],
  );
}



  Widget _buildPelajaranCard(Map<String, dynamic> pelajaran, int index) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Slot Pelajaran ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => controller.hapusPelajaran(index)),
            ],
          ),
          const SizedBox(height: 8),
          
          // Dropdown Jam Pelajaran (Ini sudah benar dan stabil)
          Obx(() {
            final jamSaatIni = pelajaran['jam'] as String?;
            final Set<String> jamTerpakai = controller.jadwalPelajaran[controller.selectedHari.value]!
                .where((p) => p['jam'] != null && p['jam'] != jamSaatIni)
                .map((p) => p['jam'] as String).toSet();
            final List<Map<String, dynamic>> jamTersedia = controller.daftarJam
                .where((jamMaster) => !jamTerpakai.contains(jamMaster['waktu'])).toList();
            return DropdownButtonFormField<String>(
              value: jamSaatIni,
              hint: const Text('Pilih Jam'),
              isExpanded: true,
              items: jamTersedia.map((jam) => DropdownMenuItem<String>(
                value: jam['waktu'],
                child: Text(jam['label'], overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (value) => controller.updatePelajaran(index, 'jam', value),
              decoration: const InputDecoration(labelText: 'Jam Pelajaran'),
            );
          }),
          
          const SizedBox(height: 8),
          // Dropdown Mata Pelajaran (Ini sudah benar dan stabil)
          DropdownButtonFormField<String>(
            value: pelajaran['idMapel'] as String?,
            hint: const Text('Pilih Mapel'),
            isExpanded: true,
            items: controller.daftarMapelTersedia.map((mapel) {
              return DropdownMenuItem<String>(value: mapel['idMapel'], child: Text(mapel['nama']));
            }).toList(),
            onChanged: (value) => controller.updatePelajaran(index, 'idMapel', value),
            decoration: const InputDecoration(labelText: 'Mata Pelajaran'),
          ),
          const SizedBox(height: 8),

          // [DIROMBAK] Dropdown Guru sekarang reaktif dan terfilter
          Obx(() {
            final idMapelTerpilih = pelajaran['idMapel'] as String?;
            
            // Filter daftar guru berdasarkan mapel yang dipilih di atas
            final guruUntukMapelIni = controller.daftarGuruTersedia
                .where((guru) => guru['idMapel'] == idMapelTerpilih)
                .toList();
            
            return DropdownButtonFormField<String>(
              value: (pelajaran['listIdGuru'] as List?)?.firstOrNull,
              
              hint: const Text('Pilih Guru'),
              isExpanded: true,
              items: guruUntukMapelIni.map((guru) {
                return DropdownMenuItem<String>(value: guru['uid'], child: Text(guru['nama']));
              }).toList(),
              onChanged: (value) => controller.updatePelajaran(index, 'idGuru', value),
              decoration: InputDecoration(
                labelText: 'Guru Pengampu',
                enabled: idMapelTerpilih != null && guruUntukMapelIni.isNotEmpty,
              ),
            );
          }),
        ],
      ),
    ),
  );
}
}
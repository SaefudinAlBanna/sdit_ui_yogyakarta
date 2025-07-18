// lib/views/buat_jadwal_pelajaran_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/buat_jadwal_pelajaran_controller.dart';

class BuatJadwalPelajaranView extends GetView<BuatJadwalPelajaranController> {
  const BuatJadwalPelajaranView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Jadwal Pelajaran'),
        centerTitle: true,
        actions: [
          Obx(() => controller.isLoading.value
              ? const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
              : IconButton(icon: const Icon(Icons.save), tooltip: "Simpan Jadwal", onPressed: controller.simpanJadwalKeFirestore)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              if (controller.isLoading.value && controller.daftarKelas.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return DropdownButtonFormField<String>(
                value: controller.selectedKelasId.value.isEmpty ? null : controller.selectedKelasId.value,
                hint: const Text('Pilih Kelas Terlebih Dahulu'),
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Kelas', border: OutlineInputBorder()),
                items: controller.daftarKelas.map((kelas) {
                  return DropdownMenuItem<String>(value: kelas['id'] as String, child: Text(kelas['nama'] as String));
                }).toList(),
                onChanged: controller.onKelasChanged,
              );
            }),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.selectedKelasId.value.isEmpty) {
                return const Expanded(child: Center(child: Text('Silakan pilih kelas untuk memulai membuat jadwal.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey))));
              } else {
                return Expanded(child: _buildScheduleEditor());
              }
            }),
          ],
        ),
      ),
      floatingActionButton: Obx(() => controller.selectedKelasId.value.isNotEmpty
          ? FloatingActionButton(onPressed: controller.tambahPelajaran, tooltip: 'Tambah Pelajaran', child: const Icon(Icons.add))
          : const SizedBox.shrink()),
    );
  }

  Widget _buildScheduleEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedHari.value,
              decoration: const InputDecoration(labelText: 'Pilih Hari', border: OutlineInputBorder()),
              items: controller.daftarHari.map((String hari) => DropdownMenuItem<String>(value: hari, child: Text(hari))).toList(),
              onChanged: controller.changeSelectedHari,
            )),
        const SizedBox(height: 20),
        Obx(() => Text('Jadwal untuk: ${controller.selectedHari.value}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        const SizedBox(height: 10),
        Expanded(
          child: Obx(() {
            final listPelajaranHariIni = controller.jadwalPelajaran[controller.selectedHari.value];
            if (listPelajaranHariIni == null || listPelajaranHariIni.isEmpty) {
              return const Center(child: Text('Belum ada pelajaran. Klik tombol + untuk menambah.'));
            }
            return ListView.builder(
              itemCount: listPelajaranHariIni.length,
              itemBuilder: (context, index) {
                final pelajaran = listPelajaranHariIni[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Jam ke-${pelajaran['jamKe']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => controller.hapusPelajaran(index)),
                          ],
                        ),
                        TextFormField(
                          initialValue: pelajaran['mapel'] as String?,
                          decoration: const InputDecoration(labelText: 'Mata Pelajaran'),
                          onChanged: (value) => controller.updatePelajaranDetail(index, 'mapel', value),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _buildTimePickerField(context, index, 'mulai', 'Jam Mulai', pelajaran['mulai'] as String?)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildTimePickerField(context, index, 'selesai', 'Jam Selesai', pelajaran['selesai'] as String?)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTimePickerField(BuildContext context, int index, String jenisWaktu, String label, String? waktu) {
    return InkWell(
      onTap: () => controller.pilihWaktu(context, index, jenisWaktu),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
        child: Text(
          waktu == null || waktu == '00:00' ? 'Pilih Waktu' : waktu,
          style: TextStyle(fontSize: 16, color: (waktu == null || waktu == '00:00') ? Colors.grey : Theme.of(context).textTheme.bodyLarge?.color),
        ),
      ),
    );
  }
}
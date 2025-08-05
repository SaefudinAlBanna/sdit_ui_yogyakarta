// File: lib/app/modules/penilaian_rapor_halaqoh/views/penilaian_rapor_halaqoh_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdit_ui_yogyakarta/app/modules/base/penilaian_siswa_item.dart'; // Impor helper class kita
import '../controllers/penilaian_rapor_halaqoh_controller.dart';

class PenilaianRaporHalaqohView extends GetView<PenilaianRaporHalaqohController> {
  const PenilaianRaporHalaqohView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Judulnya akan dinamis tergantung jenis halaqoh
        title: Text('Penilaian Rapor ${controller.jenisHalaqoh}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadData(),
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarPenilaian.isEmpty) {
          return const Center(child: Text("Tidak ada siswa untuk dinilai."));
        }
        return Column(
          children: [
            _buildPanelAksiMassal(),
            const Divider(height: 1),
            _buildHeaderTabel(),
            Expanded(
              child: ListView.builder(
                itemCount: controller.daftarPenilaian.length,
                itemBuilder: (context, index) {
                  final item = controller.daftarPenilaian[index];
                  return _buildSiswaRow(item);
                },
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: _buildTombolSimpanUtama(),
    );
  }

  // Semua widget builder di bawah ini sangat mirip dengan yang sudah kita buat,
  // menunjukkan betapa efektifnya arsitektur berbasis komponen kita.

  Widget _buildPanelAksiMassal() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[200],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.templateKeteranganC,
                  decoration: const InputDecoration(
                      labelText: 'Template Deskripsi Massal',
                      border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => controller.terapkanTemplateKeTerpilih(),
                child: const Text('Terapkan'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            label: const Text('Hapus Nilai yang Dipilih'),
            onPressed: () => controller.hapusNilaiTerpilih(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 36),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeaderTabel() {
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Obx(() => Checkbox(
            value: controller.isSelectAll.value,
            onChanged: (value) => controller.toggleSelectAll(value),
          )),
          const Expanded(flex: 3, child: Text('Nama Siswa', style: TextStyle(fontWeight: FontWeight.bold))),
          const Expanded(flex: 2, child: Text('Nilai Akhir', style: TextStyle(fontWeight: FontWeight.bold))),
          const Expanded(flex: 2, child: Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildSiswaRow(PenilaianSiswaItem<int> item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Obx(() => Checkbox(
            value: item.isSelected.value,
            onChanged: (value) => item.isSelected.value = value ?? false,
          )),
          Expanded(flex: 3, child: Text(item.siswa.nama)),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () => _showNilaiDialog(item),
              child: Obx(() => Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(item.nilai.value?.toString() ?? 'Isi Nilai', 
                  textAlign: TextAlign.center,
                  style: TextStyle(color: item.nilai.value == null ? Colors.grey : Colors.black, fontStyle: item.nilai.value == null ? FontStyle.italic : FontStyle.normal),
                ),
              )),
            ),
          ),
          Expanded(
            flex: 2,
            child: IconButton(
              icon: const Icon(Icons.edit_note, color: Colors.blue),
              onPressed: () => _showKeteranganDialog(item),
            ),
          ),
        ],
      ),
    );
  }

  void _showNilaiDialog(PenilaianSiswaItem<int> item) {
    final TextEditingController dialogC = TextEditingController(text: item.nilai.value?.toString() ?? '');
     Get.defaultDialog(
      title: 'Nilai untuk: ${item.siswa.nama}',
      content: TextFormField(
        controller: dialogC,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Nilai Angka (0-100)"),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
        ElevatedButton(onPressed: () {
          item.nilai.value = int.tryParse(dialogC.text);
          Get.back();
        }, child: const Text("Simpan Nilai")),
      ],
    );
  }

  void _showKeteranganDialog(PenilaianSiswaItem<int> item) {
    final TextEditingController dialogC = TextEditingController(text: item.keterangan.value);
    Get.defaultDialog(
      title: 'Deskripsi untuk: ${item.siswa.nama}',
      content: TextFormField(
        controller: dialogC,
        maxLines: 5,
        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Isi Deskripsi Capaian"),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
        ElevatedButton(onPressed: () {
          item.keterangan.value = dialogC.text;
          Get.back();
        }, child: const Text("Simpan Deskripsi")),
      ],
    );
  }

  Widget _buildTombolSimpanUtama() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Obx(() => ElevatedButton.icon(
        icon: controller.isSaving.value ? const SizedBox.shrink() : const Icon(Icons.save),
        label: Text(controller.isSaving.value ? 'Menyimpan...' : 'Simpan Semua Perubahan'),
        onPressed: controller.isSaving.value ? null : () => controller.simpanSemuaPerubahan(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      )),
    );
  }
}
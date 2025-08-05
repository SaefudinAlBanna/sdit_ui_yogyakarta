// File: lib/app/modules/penilaian_rapor_ekskul/views/penilaian_rapor_ekskul_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/penilaian_rapor_ekskul_controller.dart';

class PenilaianRaporEkskulView extends GetView<PenilaianRaporEkskulController> {
  const PenilaianRaporEkskulView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penilaian Rapor Ekskul'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchDataAwal(),
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.daftarNilaiSiswa.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarNilaiSiswa.isEmpty) {
          return const Center(child: Text("Tidak ada anggota di ekskul ini."));
        }
        return Column(
          children: [
            _buildPanelAksiMassal(),
            const Divider(height: 1),
            _buildHeaderTabel(),
            Expanded(
              child: ListView.builder(
                itemCount: controller.daftarNilaiSiswa.length,
                itemBuilder: (context, index) {
                  final item = controller.daftarNilaiSiswa[index];
                  return _buildSiswaRow(item, index + 1);
                },
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: _buildTombolSimpanUtama(),
    );
  }

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
                      labelText: 'Template Keterangan Massal',
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
          const Expanded(flex: 2, child: Text('Predikat', style: TextStyle(fontWeight: FontWeight.bold))),
          const Expanded(flex: 2, child: Text('Keterangan', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildSiswaRow(NilaiRaporSiswa item, int index) {
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
            child: Obx(() => DropdownButton<String>(
              isExpanded: true,
              value: item.predikat.value,
              hint: const Text('Pilih'),
              items: controller.predikatOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (value) => item.predikat.value = value,
            )),
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
  
  void _showKeteranganDialog(NilaiRaporSiswa item) {
    final TextEditingController dialogC = TextEditingController(text: item.keterangan.value);
    Get.defaultDialog(
      title: 'Keterangan: ${item.siswa.nama}',
      content: TextFormField(
        controller: dialogC,
        maxLines: 5,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
        ElevatedButton(onPressed: () {
          item.keterangan.value = dialogC.text;
          Get.back();
        }, child: const Text("Simpan Keterangan")),
      ],
    );
  }

  Widget _buildTombolSimpanUtama() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Obx(() => ElevatedButton.icon(
        icon: controller.isLoading.value ? const SizedBox.shrink() : const Icon(Icons.save),
        label: Text(controller.isLoading.value ? 'Menyimpan...' : 'Simpan Semua Perubahan'),
        onPressed: controller.isLoading.value ? null : () => controller.simpanSemuaPerubahan(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      )),
    );
  }
}
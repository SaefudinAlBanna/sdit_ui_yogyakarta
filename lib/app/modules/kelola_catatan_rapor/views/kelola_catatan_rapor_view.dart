// File: lib/app/modules/kelola_catatan_rapor/views/kelola_catatan_rapor_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/kelola_catatan_rapor_controller.dart';

class KelolaCatatanRaporView extends GetView<KelolaCatatanRaporController> {
  const KelolaCatatanRaporView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Catatan Rapor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchDataAwal(),
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarSiswaUntukCatatan.isEmpty) {
          return const Center(child: Text("Tidak ada siswa di kelas ini."));
        }
        return Column(
          children: [
            _buildPanelAksiMassal(),
            const Divider(height: 1),
            _buildHeaderTabel(),
            Expanded(
              child: ListView.builder(
                itemCount: controller.daftarSiswaUntukCatatan.length,
                itemBuilder: (context, index) {
                  final item = controller.daftarSiswaUntukCatatan[index];
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
                  controller: controller.templateCatatanC,
                  decoration: const InputDecoration(
                      labelText: 'Template Catatan Massal',
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
            label: const Text('Hapus Catatan yang Dipilih'),
            onPressed: () => controller.hapusCatatanTerpilih(),
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
          const Expanded(flex: 2, child: Text('Catatan', style: TextStyle(fontWeight: FontWeight.bold))),
          const Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSiswaRow(CatatanRaporSiswa item, int index) {
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
            child: Obx(() => Text(
              item.catatan.value.isEmpty ? "-" : item.catatan.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontStyle: item.catatan.value.isEmpty ? FontStyle.italic : FontStyle.normal),
            )),
          ),
          IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.blue),
            onPressed: () => _showCatatanDialog(item),
          ),
        ],
      ),
    );
  }

  void _showCatatanDialog(CatatanRaporSiswa item) {
    final TextEditingController dialogC = TextEditingController(text: item.catatan.value);
    Get.defaultDialog(
      title: 'Catatan untuk: ${item.siswa.nama}',
      content: TextFormField(
        controller: dialogC,
        maxLines: 7,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: "Isi Catatan Wali Kelas",
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
        ElevatedButton(onPressed: () {
          // Langsung update state reaktifnya
          item.catatan.value = dialogC.text;
          Get.back();
        }, child: const Text("Simpan Catatan")),
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
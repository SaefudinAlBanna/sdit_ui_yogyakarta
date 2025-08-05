import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/kurikulum_master_controller.dart';

class KurikulumMasterView extends GetView<KurikulumMasterController> {
  const KurikulumMasterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Kurikulum'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFaseSelector(),
          Expanded(child: _buildMapelList()),
        ],
      ),
      floatingActionButton: Obx(() => controller.faseTerpilih.value == null
          ? const SizedBox.shrink()
          : FloatingActionButton(
              onPressed: () => _showEditDialog(),
              child: const Icon(Icons.add),
              tooltip: 'Tambah Mata Pelajaran',
            )),
    );
  }

  Widget _buildFaseSelector() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.white,
      child: SizedBox(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: controller.daftarFase.map((fase) {
            return Obx(() {
              final isSelected = controller.faseTerpilih.value == fase;
              return ChoiceChip(
                label: Text(fase.replaceAll('_', ' ').toUpperCase()),
                selected: isSelected,
                onSelected: (selected) => controller.pilihFase(fase),
                selectedColor: Theme.of(Get.context!).primaryColor,
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
              );
            });
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildMapelList() {
    return Obx(() {
      if (controller.faseTerpilih.value == null) {
        return const Center(child: Text("Silakan pilih fase di atas."));
      }
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.daftarMapel.isEmpty) {
        return const Center(child: Text("Belum ada mata pelajaran untuk fase ini."));
      }
      return ListView.builder(
        itemCount: controller.daftarMapel.length,
        itemBuilder: (context, index) {
          final mapel = controller.daftarMapel[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(mapel['nama'] ?? 'Tanpa Nama'),
              subtitle: Text("Singkatan: ${mapel['singkatan'] ?? '-'}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.amber.shade700),
                    onPressed: () => _showEditDialog(mapelToEdit: mapel),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showConfirmationDialog(mapel),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  void _showEditDialog({Map<String, dynamic>? mapelToEdit}) {
    final isEditing = mapelToEdit != null;
    controller.namaMapelC.text = isEditing ? mapelToEdit['nama'] : '';
    controller.singkatanMapelC.text = isEditing ? mapelToEdit['singkatan'] : '';

    Get.defaultDialog(
      title: isEditing ? 'Edit Mata Pelajaran' : 'Tambah Mata Pelajaran',
      content: Column(
        children: [
          TextField(
            controller: controller.namaMapelC,
            decoration: const InputDecoration(labelText: 'Nama Mata Pelajaran'),
          ),
          TextField(
            controller: controller.singkatanMapelC,
            decoration: const InputDecoration(labelText: 'Nama Singkatan (Opsional)'),
          ),
        ],
      ),
      textConfirm: 'Simpan',
      confirmTextColor: Colors.white,
      onConfirm: () {
        if (isEditing) {
          controller.editMapel(mapelToEdit);
        } else {
          controller.tambahMapel();
        }
      },
      textCancel: 'Batal',
    );
  }

  void _showConfirmationDialog(Map<String, dynamic> mapel) {
    Get.defaultDialog(
      title: 'Konfirmasi Hapus',
      middleText: 'Anda yakin ingin menghapus mapel "${mapel['nama']}"?',
      textConfirm: 'Ya, Hapus',
      confirmTextColor: Colors.white,
      onConfirm: () => controller.hapusMapel(mapel),
      textCancel: 'Batal',
    );
  }
}
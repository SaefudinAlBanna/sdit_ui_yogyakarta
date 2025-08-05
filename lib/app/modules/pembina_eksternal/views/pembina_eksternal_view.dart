// File: lib/app/modules/admin_manajemen/views/pembina_eksternal_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../../../models/pembina_eksternal_model.dart';
import '../../../models/spesialisasi_model.dart';
import '../controllers/pembina_eksternal_controller.dart';

class PembinaEksternalView extends GetView<PembinaEksternalController> {
  const PembinaEksternalView({super.key});

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Pembina Eksternal'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Obx(() => SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Aktif', label: Text('Aktif')),
                ButtonSegment(value: 'Non-Aktif', label: Text('Non-Aktif')),
              ],
              selected: {controller.statusFilter.value},
              onSelectionChanged: (Set<String> newSelection) {
                controller.changeStatusFilter(newSelection.first);
              },
            )),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.daftarPembina.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarPembina.isEmpty) {
          return Center(child: Text('Belum ada data pembina ${controller.statusFilter.value.toLowerCase()}.'));
        }
        return ListView.builder(
          itemCount: controller.daftarPembina.length,
          itemBuilder: (context, index) {
            final pembina = controller.daftarPembina[index];
            final bool isActive = pembina.status == 'Aktif';
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(pembina.namaLengkap),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pembina.kontak),
                    const SizedBox(height: 4),
                    _buildSpesialisasiChips(pembina),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isActive)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showFormDialog(isUpdate: true, pembina: pembina),
                      ),
                    IconButton(
                      icon: isActive
                          ? const Icon(Icons.person_off, color: Colors.red)
                          : const Icon(Icons.person_add_alt_1, color: Colors.green),
                      tooltip: isActive ? 'Nonaktifkan' : 'Aktifkan Kembali',
                      onPressed: () {
                        if (isActive) {
                          _showDeleteConfirmation(pembina.id);
                        } else {
                          controller.reactivatePembina(pembina.id);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSpesialisasiChips(PembinaEksternalModel pembina) {
    final spesialisasiNames = pembina.spesialisasiRefs.map((id) {
      final spec = controller.opsiSpesialisasi
          .where((s) => s.id == id)
          .firstOrNull; 
      return spec?.namaSpesialisasi;
    }).where((name) => name != null).toList();

    if (spesialisasiNames.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6.0,
      runSpacing: 6.0,
      children: spesialisasiNames
          .map((name) => Chip(
                label: Text(name!, style: const TextStyle(fontSize: 12)),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                backgroundColor: Get.theme.primaryColor.withOpacity(0.1),
              ))
          .toList(),
    );
  }

  void _showFormDialog({bool isUpdate = false, PembinaEksternalModel? pembina}) {
    if (isUpdate && pembina != null) {
      controller.fillFormForEdit(pembina);
    } else {
      controller.clearForm();
    }
    
    Get.defaultDialog(
      title: isUpdate ? 'Edit Pembina' : 'Tambah Pembina Eksternal',
      content: Form(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller.namaC,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
              ),
              TextFormField(
                controller: controller.kontakC,
                decoration: const InputDecoration(labelText: 'Kontak (No. HP)'),
                 keyboardType: TextInputType.phone,
                 inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              // Multi-select dropdown
              Obx(() => MultiSelectDialogField<SpesialisasiModel>( // Tipe data eksplisit
                    // --- KESALAHAN #1 DIPERBAIKI ---
                    initialValue: controller.selectedSpesialisasi.toList().cast<SpesialisasiModel>(),
                    items: controller.opsiSpesialisasi
                        .map((s) => MultiSelectItem<SpesialisasiModel>(s, s.namaSpesialisasi))
                        .toList(),
                    title: const Text("Pilih Spesialisasi"),
                    selectedColor: Get.theme.primaryColor,
                    buttonText: const Text("Spesialisasi"),
                    onConfirm: (results) {
                      controller.selectedSpesialisasi.value = results;
                    },
                  )),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () {
            if (isUpdate && pembina != null) {
              controller.updatePembina(pembina.id);
            } else {
              controller.addPembina();
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(String id) {
    Get.defaultDialog(
      title: 'Konfirmasi Nonaktifkan',
      middleText: 'Apakah Anda yakin ingin menonaktifkan pembina ini?',
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            controller.softDeletePembina(id);
            Get.back();
          },
          child: const Text('Nonaktifkan'),
        ),
      ],
    );
  }
}
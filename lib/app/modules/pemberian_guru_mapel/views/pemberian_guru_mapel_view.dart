// lib/app/modules/pemberian_guru_mapel/views/pemberian_guru_mapel_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../controllers/pemberian_guru_mapel_controller.dart';

class PemberianGuruMapelView extends GetView<PemberianGuruMapelController> {
  const PemberianGuruMapelView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final kelas = controller.kelasTerpilih.value;
          return Text(kelas == null ? 'Atur Guru Mapel' : 'Atur Mapel Kelas $kelas');
        }),
        centerTitle: true,
        actions: [
        //   Obx(() {
        //     if (controller.kelasTerpilih.value == null) return const SizedBox.shrink();
        //     return IconButton(
        //       icon: const Icon(Icons.tune),
        //       tooltip: 'Kustomisasi Kurikulum Kelas Ini',
        //       onPressed: () => _showCustomizationDialog(context),
        //     );
        //   }),

          IconButton(onPressed: (){Get.toNamed(Routes.KURIKULUM_MASTER);}, icon: Icon(Icons.add_box_outlined)),
          IconButton(onPressed: (){Get.toNamed(Routes.MANAJEMEN_JAM);}, icon: Icon(Icons.star_border_outlined)),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            _buildKelasSelector(),
            Expanded(child: _buildMapelList()),
          ],
        );
      }),
    );
  }

  Widget _buildKelasSelector() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2, offset: const Offset(0, 2))]
      ),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.daftarKelas.length,
          itemBuilder: (context, index) {
            final namaKelas = controller.daftarKelas[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Obx(() {
                final isSelected = controller.kelasTerpilih.value == namaKelas;
                return ChoiceChip(
                  label: Text(namaKelas),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) controller.gantiKelasTerpilih(namaKelas);
                  },
                  selectedColor: Theme.of(context).primaryColor,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMapelList() {
    return Obx(() {
      if (controller.kelasTerpilih.value == null) {
        return const Center(child: Text("Silakan pilih kelas di atas untuk memulai."));
      }
      if (controller.isLoadingMapel.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.daftarMapelWajib.isEmpty) {
        return const Center(child: Text("Kurikulum untuk fase ini belum diatur."));
      }

      // final listKurikulum = controller.kurikulumFinal;
      final listKurikulum = controller.daftarMapelWajib;
      
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: controller.getAssignedMapelStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final assignedMapelData = {
            for (var doc in snapshot.data?.docs ?? [])
              doc.id: doc.data()['guru']
          };

          // --- PERUBAHAN UTAMA: Gunakan daftarMapelWajib sebagai sumber ---
          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            // itemCount: listKurikulum.length,
            itemCount: controller.daftarMapelWajib.length,
            itemBuilder: (context, index) {
              // final mapelData = controller.daftarMapelWajib[index];
              final mapelData = controller.daftarMapelWajib[index];
              final idMapel = mapelData['idMapel'] as String; // <-- Dapatkan ID
              final namaMapel = mapelData['nama'] as String;  // <-- Dapatkan Nama
              final guruDitugaskan = assignedMapelData[idMapel]; // <-- Cari berdasarkan ID

              return Card(
               margin: const EdgeInsets.only(bottom: 12.0),
               child: ListTile(
                title: Text(namaMapel, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    guruDitugaskan != null ? 'Guru: $guruDitugaskan' : 'Belum ada guru',
                    style: TextStyle(
                      color: guruDitugaskan != null ? Colors.indigo.shade800 : Colors.grey,
                      fontStyle: guruDitugaskan != null ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
                    trailing: guruDitugaskan != null 
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _showConfirmationDialog(
                          context,
                          title: 'Hapus Guru',
                          content: 'Anda yakin ingin menghapus guru dari mapel $namaMapel?',
                          // [DIROMBAK] Kirim idMapel, bukan namaMapel
                          onConfirm: () => controller.removeGuruFromMapel(idMapel),
                        ),
                      )
                    : ElevatedButton(
                        child: const Text('Atur Guru'),
                        // [DIROMBAK] Kirim seluruh objek mapelData
                        onPressed: () => _showGuruSelectionDialog(context, mapelData),
                      ),
                ),
              );
            },
          );
        },
      );
    });
  }
  
  void _showGuruSelectionDialog(BuildContext context, Map<String, dynamic> mapelData) {
   final idMapel = mapelData['idMapel'] as String;
   final namaMapel = mapelData['nama'] as String;
   Get.defaultDialog(
    title: 'Pilih Guru untuk $namaMapel',
    content: SizedBox(
        width: Get.width * 0.8,
        child: DropdownSearch<Map<String, String>>(
          popupProps: const PopupProps.menu(showSearchBox: true),
          items: (f, cs) => controller.daftarGuru,
          itemAsString: (guru) => "${guru['nama']} (${guru['role']})",
          compareFn: (item, selectedItem) => item['uid'] == selectedItem['uid'],
          decoratorProps: const DropDownDecoratorProps(
            decoration: InputDecoration(labelText: "Pilih Guru"),
          ),
          onChanged: (Map<String, String>? selectedGuru) {
          if (selectedGuru != null) {
            Get.back();
            _showConfirmationDialog(
              context,
              title: 'Konfirmasi',
              content: 'Tugaskan ${selectedGuru['nama']} ke mapel $namaMapel?',
              onConfirm: () => controller.assignGuruToMapel(
                selectedGuru['uid']!,
                selectedGuru['nama']!,
                idMapel,      // <-- Kirim ID
                namaMapel,    // <-- Kirim Nama
              ),
            );
          }
        },
      ),
    ));
  }

  void _showConfirmationDialog(BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    Get.defaultDialog(
      title: title,
      middleText: content,
      textConfirm: 'Ya',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        onConfirm();
      },
    );
  }
}
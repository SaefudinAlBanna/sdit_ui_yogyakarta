// lib/app/modules/pemberian_guru_mapel/views/pemberian_guru_mapel_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: controller.getAssignedMapelStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final assignedMapelData = {
            for (var doc in snapshot.data?.docs ?? [])
              doc.data()['namamatapelajaran']: doc.data()['guru']
          };

          // --- PERUBAHAN UTAMA: Gunakan daftarMapelWajib sebagai sumber ---
          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: controller.daftarMapelWajib.length,
            itemBuilder: (context, index) {
              final namaMapel = controller.daftarMapelWajib[index];
              final guruDitugaskan = assignedMapelData[namaMapel];

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
                  trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tombol baru untuk mengatur bobot
                        // IconButton(
                        //   icon: const Icon(Icons.percent_rounded, color: Colors.blue),
                        //   tooltip: "Atur Bobot Penilaian",
                        //   onPressed: () => _showBobotDialog(context, namaMapel, guruDitugaskan),
                        // ),
                        guruDitugaskan != null 
                             ? IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _showConfirmationDialog(
                            context,
                            title: 'Hapus Guru',
                            content: 'Anda yakin ingin menghapus guru dari mapel $namaMapel?',
                            onConfirm: () => controller.removeGuruFromMapel(namaMapel),
                          ),
                        )
                      : ElevatedButton(
                          child: const Text('Atur Guru'),
                          onPressed: () => _showGuruSelectionDialog(context, namaMapel),
                        ),
                      ],
                    )
                ),
              );
            },
          );
        },
      );
    });
  }

//   void _showBobotDialog(BuildContext context, String namaMapel, String? guru) {
//   // Buat controller untuk setiap field
//   final harianC = TextEditingController(text: "25"); // Nilai default
//   final ulanganC = TextEditingController(text: "25");
//   final ptsC = TextEditingController(text: "25");
//   final pasC = TextEditingController(text: "25");

//   Get.defaultDialog(
//     title: "Atur Bobot Nilai: $namaMapel",
//     content: Column(
//       children: [
//         TextField(controller: harianC, decoration: const InputDecoration(labelText: "Bobot Harian/PR (%)"), keyboardType: TextInputType.number),
//         TextField(controller: ulanganC, decoration: const InputDecoration(labelText: "Bobot Ulangan Harian (%)"), keyboardType: TextInputType.number),
//         TextField(controller: ptsC, decoration: const InputDecoration(labelText: "Bobot PTS (%)"), keyboardType: TextInputType.number),
//         TextField(controller: pasC, decoration: const InputDecoration(labelText: "Bobot PAS (%)"), keyboardType: TextInputType.number),
//       ],
//     ),
//     confirm: ElevatedButton(
//       onPressed: () {
//         final bobot = {
//           'namaMapel': namaMapel,
//           'harian': int.tryParse(harianC.text) ?? 0,
//           'ulangan': int.tryParse(ulanganC.text) ?? 0,
//           'pts': int.tryParse(ptsC.text) ?? 0,
//           'pas': int.tryParse(pasC.text) ?? 0,
//           'tambahan': 0, // Default
//         };
//         controller.simpanBobotNilai(bobot);
//       },
//       child: const Text("Simpan Bobot")
//     )
//   );
//  }
  
  void _showGuruSelectionDialog(BuildContext context, String namaMapel) {
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
                  namaMapel,
                ),
              );
            }
          },
        ),
      ),
    );
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
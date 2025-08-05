// lib/app/modules/manajemen_jam/views/manajemen_jam_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/manajemen_jam_controller.dart';

class ManajemenJamView extends GetView<ManajemenJamController> {
  const ManajemenJamView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Jam Pelajaran'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: controller.streamJamPelajaran(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada jam pelajaran."));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80), // Padding untuk FAB
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data();
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text(data['urutan'].toString())),
                  title: Text(data['namaKegiatan'] ?? 'Tanpa Nama'),
                  subtitle: Text("Waktu: ${data['jampelajaran']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // IconButton(icon: const Icon(Icons.edit, color: Colors.amber.shade700), onPressed: () => _showEditDialog(context, doc: doc)),
                      IconButton(icon: const Icon(Icons.edit, color: Colors.amberAccent,), onPressed: () => _showEditDialog(context, doc: doc)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _showDeleteConfirmation(context, doc.id)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, {DocumentSnapshot? doc}) {
    final bool isEditing = doc != null;
    if (isEditing) {
      final data = doc.data() as Map<String, dynamic>;
      controller.namaC.text = data['namaKegiatan'] ?? '';
      // Konversi string HH:mm ke TimeOfDay
      final parseTime = (String timeStr) {
        final parts = timeStr.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      };
      controller.jamMulai.value = parseTime(data['jamMulai']);
      controller.jamSelesai.value = parseTime(data['jamSelesai']);
    } else {
      controller.namaC.clear();
      controller.jamMulai.value = null;
      controller.jamSelesai.value = null;
    }

    Get.defaultDialog(
      title: isEditing ? "Edit Jam Pelajaran" : "Tambah Jam Pelajaran",
      content: Column(
        children: [
          TextField(controller: controller.namaC, decoration: const InputDecoration(labelText: 'Nama Kegiatan')),
          const SizedBox(height: 16),
          // [DIROMBAK] Menggunakan InkWell dan Obx untuk memilih waktu
          Obx(() => _buildTimePickerField(context, 'Jam Mulai', controller.jamMulai.value, () => controller.pilihWaktu(context, 'mulai'))),
          const SizedBox(height: 8),
          Obx(() => _buildTimePickerField(context, 'Jam Selesai', controller.jamSelesai.value, () => controller.pilihWaktu(context, 'selesai'))),
          // [DIHAPUS] TextField untuk Nomor Urut sudah tidak ada
        ],
      ),
      confirm: ElevatedButton(onPressed: () => controller.simpanJam(docId: isEditing ? doc.id : null), child: const Text("Simpan")),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }
  
  // [BARU] Widget helper untuk field pemilihan waktu
  Widget _buildTimePickerField(BuildContext context, String label, TimeOfDay? time, VoidCallback onTap) {
    final String timeText = time != null ? time.format(context) : 'Pilih Waktu';
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        child: Text(timeText),
      ),
    );
  }

    void _showDeleteConfirmation(BuildContext context, String docId) {
    Get.defaultDialog(
      title: "Konfirmasi",
      middleText: "Anda yakin ingin menghapus jam pelajaran ini?",
      textConfirm: "Ya, Hapus",
      confirmTextColor: Colors.white,
      onConfirm: () => controller.hapusJam(docId),
      textCancel: "Batal",
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// import '../controllers/manajemen_jam_controller.dart';

// class ManajemenJamView extends GetView<ManajemenJamController> {
//   const ManajemenJamView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Manajemen Jam Pelajaran'),
//         centerTitle: true,
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showEditDialog(context),
//         child: const Icon(Icons.add),
//       ),
//       body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//         stream: controller.streamJamPelajaran(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text("Belum ada jam pelajaran."));
//           }

//           return ListView.builder(
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               final doc = snapshot.data!.docs[index];
//               final data = doc.data();
              
//               return Card(
//                 margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 child: ListTile(
//                   leading: CircleAvatar(child: Text(data['urutan'].toString())),
//                   title: Text(data['namaKegiatan'] ?? 'Tanpa Nama'),
//                   subtitle: Text("Waktu: ${data['jamMulai']} - ${data['jamSelesai']}"),
//                   trailing: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       IconButton(
//                         icon: const Icon(Icons.edit, color: Colors.amber),
//                         onPressed: () => _showEditDialog(context, doc: doc),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.delete, color: Colors.red),
//                         onPressed: () => _showDeleteConfirmation(context, doc.id),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   void _showEditDialog(BuildContext context, {DocumentSnapshot? doc}) {
//     final bool isEditing = doc != null;
//     if (isEditing) {
//       final data = doc.data() as Map<String, dynamic>;
//       controller.namaC.text = data['namaKegiatan'] ?? '';
//       controller.mulaiC.text = data['jamMulai'] ?? '';
//       controller.selesaiC.text = data['jamSelesai'] ?? '';
//       controller.urutanC.text = data['urutan']?.toString() ?? '';
//     } else {
//       controller.namaC.clear();
//       controller.mulaiC.clear();
//       controller.selesaiC.clear();
//       controller.urutanC.clear();
//     }

//     Get.defaultDialog(
//       title: isEditing ? "Edit Jam Pelajaran" : "Tambah Jam Pelajaran",
//       content: Column(
//         children: [
//           TextField(controller: controller.namaC, decoration: const InputDecoration(labelText: 'Nama Kegiatan')),
//           TextField(controller: controller.mulaiC, decoration: const InputDecoration(labelText: 'Jam Mulai (HH.mm)')),
//           TextField(controller: controller.selesaiC, decoration: const InputDecoration(labelText: 'Jam Selesai (HH.mm)')),
//           TextField(controller: controller.urutanC, decoration: const InputDecoration(labelText: 'Nomor Urut'), keyboardType: TextInputType.number),
//         ],
//       ),
//       confirm: ElevatedButton(
//         onPressed: () => controller.simpanJam(docId: isEditing ? doc.id : null),
//         child: const Text("Simpan"),
//       ),
//       cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
//     );
//   }

//   void _showDeleteConfirmation(BuildContext context, String docId) {
//     Get.defaultDialog(
//       title: "Konfirmasi",
//       middleText: "Anda yakin ingin menghapus jam pelajaran ini?",
//       textConfirm: "Ya, Hapus",
//       confirmTextColor: Colors.white,
//       onConfirm: () => controller.hapusJam(docId),
//       textCancel: "Batal",
//     );
//   }
// }
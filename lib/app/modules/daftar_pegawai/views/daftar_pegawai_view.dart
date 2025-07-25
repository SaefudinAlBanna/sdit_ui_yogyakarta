// lib/app/modules/daftar_pegawai/views/daftar_pegawai_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../manajemen_jabatan/views/manajemen_jabatan_view.dart';
import '../../manajemen_tugas/views/manajemen_tugas_view.dart';
import '../../tambah_pegawai/bindings/tambah_pegawai_binding.dart';
import '../../tambah_pegawai/views/tambah_pegawai_view.dart';
import '../controllers/daftar_pegawai_controller.dart'; // <-- IMPORT CONTROLLER BARU

// Ubah menjadi GetView yang terhubung dengan controller
class DaftarPegawaiView extends GetView<DaftarPegawaiController> {
  const DaftarPegawaiView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Daftarkan controller ke GetX
    Get.put(DaftarPegawaiController());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Data Pegawai'),
        actions: [
          IconButton(
            icon: Icon(Icons.assignment_ind_outlined),
            tooltip: 'Kelola Tugas Tambahan',
            onPressed: () => Get.to(() => ManajemenTugasView()),
          ),
          IconButton(
            icon: Icon(Icons.admin_panel_settings_outlined),
            tooltip: 'Kelola Jabatan',
            onPressed: () => Get.to(() => ManajemenJabatanView()),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: controller.searchC,
              onChanged: (value) => controller.searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Cari nama, jabatan, atau tugas...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      // Gunakan Obx untuk membuat UI menjadi reaktif
      body: Obx(() {
        if (controller.isLoading.isTrue) {
          return Center(child: CircularProgressIndicator());
        }

        // if (controller.daftarPegawai.isEmpty) {
        //   return Center(
        //     child: Text(
        //       'Belum ada data pegawai.\nTekan tombol + untuk menambah.',
        //       textAlign: TextAlign.center,
        //     ),
        //   );
        // }
        if (controller.daftarPegawaiFiltered.isEmpty) { 
          return Center(child: Text('Data tidak ditemukan.'));
        }

        // Tampilkan daftar menggunakan ListView.builder
        return RefreshIndicator(
          onRefresh: () => controller.fetchPegawai(), // Tambahkan fitur pull-to-refresh
          child: ListView.builder(
            itemCount: controller.daftarPegawaiFiltered.length,
            itemBuilder: (context, index) {
              final doc = controller.daftarPegawaiFiltered[index];
              final data = doc.data() as Map<String, dynamic>;

              final String nama = data['nama'] ?? 'Tanpa Nama';
              final String role = data['role'] ?? 'Tanpa Jabatan';
              final List<dynamic> tugasList = data['tugas'] ?? [];
              final String tugas = tugasList.isNotEmpty ? tugasList.join(', ') : '-';
              final String? profileImageUrl = data['profileImageUrl'];

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      // Tampilkan gambar dari network jika URL ada
                      backgroundImage: profileImageUrl != null
                          ? NetworkImage(profileImageUrl)
                          : null,
                      // Tampilkan initial nama HANYA jika tidak ada gambar
                      child: profileImageUrl == null
                          ? Text(
                              nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : null,
                    ),
                  title: Text(nama, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Jabatan: $role", style: TextStyle(color: theme.primaryColor)),
                      Text("Tugas: $tugas"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tombol Edit (untuk masa depan)
                      IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue.shade700),
                          onPressed: () async {
                            // Navigasi ke TambahPegawaiView dan KIRIM DATA sebagai arguments
                            final result = await Get.to(
                              () => TambahPegawaiView(),
                              binding: TambahPegawaiBinding(),
                              arguments: {
                                'id': doc.id,
                                'data': data,
                              },
                            );
                            // Jika kembali dengan sinyal sukses, refresh daftar
                            if (result == true) {
                              controller.fetchPegawai();
                            }
                          },
                          tooltip: 'Edit Pegawai',
                        ),
                      // Tombol Hapus
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                        onPressed: () {
                          // Panggil fungsi hapus dari controller
                          controller.hapusPegawai(doc.id, nama);
                        },
                        tooltip: 'Hapus Pegawai',
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigasi ke halaman tambah pegawai.
          // Setelah kembali, panggil fetchPegawai() untuk refresh data.
          final result = await Get.to(() => TambahPegawaiView(), binding: TambahPegawaiBinding());
          if (result == true) { // Jika halaman tambah pegawai ditutup dgn sukses
             controller.fetchPegawai();
          }
        },
        child: Icon(Icons.person_add),
        tooltip: 'Tambah Pegawai Baru',
      ),
    );
  }
}
// lib/app/modules/daftar_kelas/views/daftar_kelas_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../controllers/daftar_kelas_controller.dart';

class DaftarKelasView extends GetView<DaftarKelasController> {
  const DaftarKelasView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mata Pelajaran'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.grey.shade800,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Widget untuk Pemilihan Kelas ---
          _buildKelasSelector(context),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Daftar Mapel",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          // --- Widget untuk Menampilkan Daftar Mata Pelajaran ---
          Expanded(
            child: _buildMapelList(),
          ),
        ],
      ),
    );
  }

  /// Widget untuk menampilkan daftar kelas yang bisa dipilih.
  Widget _buildKelasSelector(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingKelas.value) {
        return const Center(child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ));
      }

      if (controller.daftarKelasDiajar.isEmpty) {
        return const Center(child: Text("Anda tidak mengajar di kelas manapun."));
      }

      // Tampilan Pilihan Kelas dalam bentuk Chip yang bisa di-scroll horizontal
      return SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: controller.daftarKelasDiajar.length,
          itemBuilder: (context, index) {
            final namaKelas = controller.daftarKelasDiajar[index];
            final isSelected = controller.kelasTerpilih.value == namaKelas;
            
            return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Obx(() { // <-- Bungkus setiap chip dengan Obx-nya sendiri
                  final isSelected = controller.kelasTerpilih.value == namaKelas;
                  return ChoiceChip(
                    label: Text(namaKelas),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    selected: isSelected, // <--- Ini yang menentukan tampilan centang
                    onSelected: (selected) {
                      // Logika ini sudah benar, kita pastikan saja ia terpanggil
                      if (selected) {
                        controller.gantiKelasTerpilih(namaKelas);
                      }
                    },
                    selectedColor: Colors.green.shade600,
                    backgroundColor: Colors.grey.shade200,
                    avatar: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null, // <-- Tambahkan ini
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Colors.green.shade700 : Colors.grey.shade300,
                        width: 1.5
                      )
                    ),
                  );
                }),
              );
          },
        ),
      );
    });
  }

  /// Widget untuk menampilkan daftar mata pelajaran berdasarkan kelas yang dipilih.
  Widget _buildMapelList() {
    return Obx(() {
      if (controller.isLoadingMapel.value) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (controller.kelasTerpilih.value == null) {
        return const Center(child: Text("Silakan pilih kelas terlebih dahulu."));
      }

      if (controller.daftarMapel.isEmpty) {
        return const Center(child: Text("Tidak ada mata pelajaran di kelas ini."));
      }
      
      // Tampilan daftar mapel dengan Card yang lebih menarik
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.daftarMapel.length,
        itemBuilder: (context, index) {
          final mapel = controller.daftarMapel[index];
          final namaMapel = mapel['namaMapel'] ?? 'Tanpa Nama';
          final idKelas = mapel['idKelas'] ?? 'Tanpa ID';

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.withOpacity(0.1),
                child: Icon(Icons.book_outlined, color: Colors.green.shade700),
              ),
              title: Text(namaMapel, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(idKelas),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                // Kirim data sebagai Map agar mudah diakses di halaman selanjutnya
                Get.toNamed(
                  Routes.DAFTAR_SISWA_PERMAPEL,
                  arguments: {
                    'idKelas': idKelas,       // misal: '1B-UMUM'
                    'namaMapel': namaMapel,   // misal: 'Bahasa Arab'
                  },
                );
              },
            ),
          );
        },
      );
    });
  }
}
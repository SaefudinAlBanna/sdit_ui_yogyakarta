// lib/app/modules/daftar_siswa_permapel/views/daftar_siswa_permapel_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Import lain yang diperlukan...
import '../../../routes/app_pages.dart';
import '../../input_nilai_siswa/bindings/input_nilai_siswa_binding.dart';
import '../../input_nilai_siswa/views/input_nilai_siswa_view.dart';
import '../../rapor_siswa/bindings/rapor_siswa_binding.dart';
import '../../rapor_siswa/views/rapor_siswa_view.dart';
import '../controllers/daftar_siswa_permapel_controller.dart';

class DaftarSiswaPermapelView extends GetView<DaftarSiswaPermapelController> {
  const DaftarSiswaPermapelView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Obx(() => Text(controller.appBarTitle.value)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.grey.shade800,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarSiswa.isEmpty) {
          return const Center(
            child: Text(
              "Belum ada siswa di kelas ini.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        // Jika data ada, tampilkan list
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          itemCount: controller.daftarSiswa.length,
          itemBuilder: (context, index) {
            final siswa = controller.daftarSiswa[index];
            return _SiswaCard(siswa: siswa); // Gunakan widget custom yang baru
          },
        );
      }),
    );
  }
}


/// Widget Card kustom versi sederhana dengan tombol di samping.
class _SiswaCard extends StatelessWidget {
  final Map<String, dynamic> siswa;
  final DaftarSiswaPermapelController controller = Get.find();

  _SiswaCard({required this.siswa, super.key});

  @override
  Widget build(BuildContext context) {
    final String namaSiswa = siswa['namasiswa'] ?? 'Nama tidak ada';
    final String nis = siswa['nis'] ?? 'NIS tidak ada';
    final String idSiswa = siswa['idSiswa'];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: (){
          Get.to(
                () => InputNilaiSiswaView(),
                binding: InputNilaiSiswaBinding(),
                arguments: {
                  'idKelas': controller.idKelas,
                  'idMapel': controller.namaMapel,
                  'idSiswa': idSiswa,
                  'namaSiswa': namaSiswa,
                },
              );
        },
        // Avatar di sebelah kiri
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Text(
            namaSiswa.isNotEmpty ? namaSiswa[0].toUpperCase() : 'S',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
        ),
        // Nama dan NIS di tengah
        title: Text(namaSiswa, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("NIS: $nis", style: TextStyle(color: Colors.grey.shade600)),
        
        // Tombol-tombol aksi di sebelah kanan
        trailing: Row(
          mainAxisSize: MainAxisSize.min, // Agar Row hanya memakan tempat seperlunya
          children: [
            // Tombol Input Nilai
            Tooltip(
              message: "Input Nilai",
              child: IconButton(
                icon: Icon(Icons.edit_note, color: Colors.blue.shade700),
                onPressed: () {
                   Get.to(
                    () => InputNilaiSiswaView(),
                    binding: InputNilaiSiswaBinding(),
                    arguments: {
                      'idKelas': controller.idKelas,
                      'idMapel': controller.namaMapel,
                      'idSiswa': idSiswa,
                      'namaSiswa': namaSiswa,
                    },
                  );
                },
              ),
            ),
            // Tombol Lihat Rapor
            Tooltip(
              message: "Lihat Rapor",
              child: IconButton(
                icon: Icon(Icons.assignment_ind_outlined, color: Colors.orange.shade700),
                onPressed: () {
                  Get.to(
                    () => RaporSiswaView(),
                    binding: RaporSiswaBinding(),
                    arguments: {
                      'idSiswa': idSiswa,
                      'namaSiswa': namaSiswa,
                      'idKelas': controller.idKelas,
                    },
                  );
                },
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      ),
    );
  }
}
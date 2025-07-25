// lib/app/modules/analisis_akademik/views/analisis_akademik_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../controllers/analisis_akademik_controller.dart';
import '../../../models/analisis_akademik_model.dart';

class AnalisisAkademikWidget extends GetWidget<AnalisisAkademikController> {
  // Tambahkan tag agar widget ini bisa menemukan controller yang tepat
  @override
  final String? tag;

  const AnalisisAkademikWidget({this.tag, super.key});

  @override
  Widget build(BuildContext context) {
    // Panggil fungsi untuk memuat data saat widget pertama kali ditampilkan
    // Kita lakukan ini di sini agar setiap kali tab diklik, datanya bisa di-refresh
    // controller.loadAndAnalyzeData();

    final AnalisisAkademikController controller = Get.find<AnalisisAkademikController>(tag: tag);
    
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      
      // --- [PERBAIKAN] Gunakan state isDataAvailable untuk memilih tampilan ---
      if (controller.isDataAvailable.value) {
        final hasil = controller.hasilAnalisis.value;
        // Tampilkan konten rapor jika hasil tidak null
        if (hasil != null) {
          return RefreshIndicator(
            onRefresh: () => controller.loadAndAnalyzeData(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatistikCard(hasil),
                const SizedBox(height: 24),
                Text("Peringkat Kelas (berdasarkan nilai rata-rata)", style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDaftarSiswa(hasil.daftarSiswa, controller),
              ],
            ),
          );
        }
        // Fallback jika data available tapi hasil null (jarang terjadi)
        return const Center(child: Text("Terjadi kesalahan saat menampilkan data."));
      } else {
        // Jika data tidak tersedia, tampilkan Empty State
        return _buildEmptyState(controller);
      }
    });
  }

  Widget _buildEmptyState(AnalisisAkademikController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 100, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              "Data Akademik Belum Tersedia",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Belum ada siswa atau data rapor yang diinisialisasi untuk kelas ini pada semester berjalan.",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Tombol Aksi HANYA untuk Admin
            if (controller.isAdmin)
              ElevatedButton.icon(
                icon: const Icon(Icons.add_chart_rounded),
                label: const Text("Inisialisasi Data Rapor"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Get.snackbar("Info", "Navigasi ke halaman setup rapor.");
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Widget untuk menampilkan kartu statistik di bagian atas.
  Widget _buildStatistikCard(KelasAkademikModel hasil) {
    return Card(
      elevation: 4,
      color: Get.theme.primaryColor.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text("Rata-Rata Kelas", style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(hasil.rataRataKelas.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),
            Column(
              children: [
                Text("Jumlah Siswa", style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(hasil.daftarSiswa.length.toString(), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Widget untuk menampilkan daftar siswa.
  Widget _buildDaftarSiswa(List<SiswaAkademikModel> daftarSiswa, AnalisisAkademikController controller) {
    if (daftarSiswa.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Tidak ada siswa di kelas ini.")));
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: daftarSiswa.length,
      itemBuilder: (context, index) {
        final siswa = daftarSiswa[index];
        final rank = index + 1;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(child: Text(rank.toString())),
            title: Text(siswa.namaSiswa, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Text(siswa.rataRataNilai?.toStringAsFixed(2) ?? 'N/A', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onTap: () {
              Get.toNamed(
                Routes.RAPOR_SISWA,
                arguments: {'idSiswa': siswa.idSiswa, 'namaSiswa': siswa.namaSiswa, 'idKelas': controller.idKelas},
              );
            },
          ),
        );
      },
    );
  }
}
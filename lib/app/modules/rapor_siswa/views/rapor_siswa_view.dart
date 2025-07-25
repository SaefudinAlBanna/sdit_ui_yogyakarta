import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/rapor_siswa_model.dart'; // <-- Jangan lupa import model
import '../controllers/rapor_siswa_controller.dart';

class RaporSiswaView extends GetView<RaporSiswaController> {
  const RaporSiswaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Rapor Belajar Siswa', style: TextStyle(fontSize: 18)),
            // Ambil nama siswa dari controller untuk ditampilkan di app bar
            Text(controller.namaSiswa, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
          icon: const Icon(Icons.picture_as_pdf_outlined),
          tooltip: "Ekspor ke PDF",
          onPressed: () {
            controller.exportRaporToPdf();
          },
        ),
        ],
      ),
      body: Obx(() {
        // Tampilkan loading indicator selama data diproses
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // Tampilkan pesan jika tidak ada data rapor sama sekali
        if (controller.raporData.isEmpty) {
          return const Center(
            child: Text(
              "Data rapor untuk semester ini belum tersedia.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          );
        }

        // Jika data ada, tampilkan sebagai daftar
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: controller.raporData.length,
          itemBuilder: (context, index) {
            final mapelData = controller.raporData[index];
            return _buildMapelCard(mapelData);
          },
        );
      }),
    );
  }

  /// Widget untuk membangun kartu per mata pelajaran.
  Widget _buildMapelCard(RaporMapelModel mapelData) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // Gunakan ExpansionTile agar rapor bisa dibuka-tutup
      child: ExpansionTile(
        // Header (saat tertutup)
        leading: CircleAvatar(
          backgroundColor: Get.theme.primaryColor.withOpacity(0.1),
          foregroundColor: Get.theme.primaryColor,
          child: Text(
            mapelData.nilaiAkhir?.toStringAsFixed(0) ?? '-', // Tampilkan nilai bulat
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(mapelData.namaMapel, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Guru: ${mapelData.guruPengajar}"),
        
        // Konten (saat dibuka)
        children: [
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildDetailCapaian(mapelData),
          )
        ],
      ),
    );
  }

  /// Widget untuk membangun detail capaian di dalam kartu.
  Widget _buildDetailCapaian(RaporMapelModel mapelData) {
    // Jika tidak ada data capaian sama sekali
    if (mapelData.daftarCapaian.isEmpty) {
      return const Text(
        "Deskripsi capaian untuk mata pelajaran ini belum diisi oleh guru.",
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }
    
    // Jika ada, tampilkan per unit
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: mapelData.daftarCapaian.map((unit) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Judul Unit/Bab
              Text(
                unit.namaUnit,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              
              // Tampilkan daftar TP yang Tercapai
              if (unit.tpTercapai.isNotEmpty)
                _buildTpList(
                  title: "Telah menguasai dengan baik:",
                  tps: unit.tpTercapai,
                  icon: Icons.check_circle_outline,
                  color: Colors.green.shade700,
                ),
              
              // Tampilkan daftar TP yang Perlu Bimbingan
              if (unit.tpPerluBimbingan.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildTpList(
                  title: "Memerlukan bimbingan lebih lanjut dalam:",
                  tps: unit.tpPerluBimbingan,
                  icon: Icons.highlight_outlined,
                  color: Colors.orange.shade800,
                ),
              ]
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Helper widget untuk membangun daftar TP (baik yang tercapai maupun perlu bimbingan).
  Widget _buildTpList({
    required String title,
    required List<String> tps,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        ...tps.map((tp) => Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(tp)),
            ],
          ),
        )).toList(),
      ],
    );
  }
}
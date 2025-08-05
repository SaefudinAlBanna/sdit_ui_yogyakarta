import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../controllers/laporan_ekskul_controller.dart';

class LaporanDetailView extends GetView<LaporanEkskulController> {
  const LaporanDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
          controller.laporanTerpilih.value?.namaEkskulLengkap ?? 'Detail Laporan',
          overflow: TextOverflow.ellipsis,
        )),
      ),
      body: Obx(() {
        if (controller.isLoadingDetail.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.laporanTerpilih.value == null) {
          return const Center(child: Text("Tidak ada data ekskul yang dipilih."));
        }

        final laporan = controller.laporanTerpilih.value!;
        final anggota = controller.daftarAnggotaDetail;
        final sebaran = controller.sebaranKelas;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Bagian Visualisasi Data ---
              const Text("Sebaran Anggota per Kelas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (sebaran.isEmpty)
                const Text("Belum ada anggota untuk divisualisasikan."),
              ...sebaran.entries.map((entry) {
                double percentage = entry.value / laporan.jumlahAnggota;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${entry.key} (${entry.value} siswa)", style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      LinearPercentIndicator(
                        percent: percentage,
                        lineHeight: 20.0,
                        center: Text("${(percentage * 100).toStringAsFixed(1)}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        progressColor: Colors.blue,
                        barRadius: const Radius.circular(10),
                      ),
                    ],
                  ),
                );
              }).toList(),

              const Divider(height: 40),

              // --- Bagian Daftar Anggota ---
              const Text("Daftar Anggota", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (anggota.isEmpty)
                const Text("Tidak ada anggota terdaftar."),
              ...anggota.asMap().entries.map((entry) {
                int index = entry.key;
                var siswa = entry.value;
                return ListTile(
                  leading: CircleAvatar(child: Text("${index + 1}")),
                  title: Text(siswa.nama),
                  subtitle: Text("Kelas: ${siswa.namaKelas}"),
                );
              }).toList(),
            ],
          ),
        );
      }),
    );
  }
}
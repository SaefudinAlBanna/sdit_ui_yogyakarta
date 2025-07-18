// =========================================================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/rekapitulasi_pembayaran_controller.dart';

class RekapitulasiPembayaranView extends GetView<RekapitulasiPembayaranController> {
  const RekapitulasiPembayaranView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekapitulasi Pembayaran'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.hitungRekapitulasi(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(controller.statusMessage.value),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildTotalSekolahCard(),
            const SizedBox(height: 24),
            const Text("Rekapitulasi per Kelas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(thickness: 1.5),
            const SizedBox(height: 8),
            if (controller.rekapPerKelas.isEmpty)
              const Center(child: Text("Tidak ada data kelas ditemukan."))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.rekapPerKelas.length,
                itemBuilder: (context, index) {
                  final rekap = controller.rekapPerKelas[index];
                  // --- PERUBAHAN UTAMA DI SINI ---
                  return _buildRekapKelasExpansionTile(rekap);
                },
              ),
          ],
        );
      }),
    );
  }

  // --- UBAH CARD MENJADI EXPANSIONTILE ---
  Widget _buildRekapKelasExpansionTile(RekapKelas rekap) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        title: Text("Kelas: ${rekap.namaKelas}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text("Jumlah Siswa: ${rekap.jumlahSiswa} orang"),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.arrow_downward, "Total Diterima:",
                  controller.formatRupiah(rekap.totalPenerimaan), Colors.green[700]!,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.warning_amber_rounded, "Total Kekurangan:",
                  controller.formatRupiah(rekap.totalKekurangan), Colors.orange[800]!,
                ),
                const Divider(height: 20),
                const Text("Rincian:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                // Tampilkan rincian per jenis pembayaran
                ...rekap.rincian.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("  • ${item.namaItem}"),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(controller.formatRupiah(item.totalDiterima), style: TextStyle(color: Colors.green, fontSize: 12)),
                          Text(controller.formatRupiah(item.totalKekurangan), style: TextStyle(color: Colors.red, fontSize: 12)),
                        ],
                      )
                    ],
                  ),
                )).toList(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTotalSekolahCard() {
    return Card(
      elevation: 4.0,
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Total Rekapitulasi Sekolah",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            SizedBox(height: 4),
            Text("Total Siswa: ${controller.totalSiswaSekolah.value} orang"),
            Divider(),
            SizedBox(height: 8),
            _buildInfoRow(
              Icons.check_circle,
              "Total Uang Diterima:",
              controller.formatRupiah(controller.totalPenerimaanSekolah.value),
              Colors.green,
            ),
            SizedBox(height: 12),
            _buildInfoRow(
              Icons.error,
              "Total Kekurangan Bayar:",
              controller.formatRupiah(controller.totalKekuranganSekolah.value),
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRekapKelasCard(RekapKelas rekap) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Kelas: ${rekap.namaKelas}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text("Jumlah Siswa: ${rekap.jumlahSiswa} orang"),
            Divider(),
            _buildInfoRow(
              Icons.arrow_downward,
              "Uang Diterima:",
              controller.formatRupiah(rekap.totalPenerimaan),
              Colors.green[700]!,
            ),
            SizedBox(height: 8),
            _buildInfoRow(
              Icons.warning_amber_rounded,
              "Kekurangan Bayar:",
              controller.formatRupiah(rekap.totalKekurangan),
              Colors.orange[800]!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 15),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
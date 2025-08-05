import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/rekap_absensi_controller.dart';

class RekapAbsensiWidget extends GetView<RekapAbsensiController> {
  // Tambahkan konstruktor agar bisa dipanggil dari mana saja
  final String? tag;
  const RekapAbsensiWidget({super.key, this.tag});

  @override
  Widget build(BuildContext context) {
    // Inti dari UI kita: Column yang berisi panel kontrol dan hasil
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildControlPanel(context),
          const Divider(height: 32),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.rekapData.isEmpty) {
                return const Center(
                  child: Text(
                    "Pilih rentang tanggal, lalu klik 'Tampilkan Rekap'.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }
              return _buildRekapTable();
            }),
          ),
        ],
      ),
    );
  }

  

  /// Widget untuk panel kontrol di bagian atas.
  Widget _buildControlPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Baris untuk memilih tanggal
        Row(
          children: [
            Expanded(
              child: _buildDatePicker(
                context: context,
                label: "Tanggal Mulai",
                date: controller.tanggalMulai,
                onTap: () => controller.pilihTanggalMulai(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDatePicker(
                context: context,
                label: "Tanggal Selesai",
                date: controller.tanggalSelesai,
                onTap: () => controller.pilihTanggalSelesai(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Tombol untuk memproses rekap
        ElevatedButton.icon(
          onPressed: () => controller.getRekapAbsensi(),
          icon: const Icon(Icons.calculate_outlined),
          label: const Text("Tampilkan Rekap"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  /// Widget helper untuk membuat pemilih tanggal.
  Widget _buildDatePicker({
    required BuildContext context,
    required String label,
    required Rx<DateTime> date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: Colors.grey),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Obx(() => Text(
                      DateFormat('dd MMM yyyy').format(date.value),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Widget untuk membangun tabel data rekapitulasi.
  Widget _buildRekapTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingRowColor: MaterialStateColor.resolveWith((states) => Colors.blue.shade50),
          columns: const [
            DataColumn(label: Text('No.', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Nama Siswa', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('S', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)), numeric: true),
            DataColumn(label: Text('I', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)), numeric: true),
            DataColumn(label: Text('A', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)), numeric: true),
          ],
          rows: controller.rekapData.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            return DataRow(
              cells: [
                DataCell(Text((index + 1).toString())),
                DataCell(Text(data.namaSiswa)),
                DataCell(Text(data.sakitCount.toString(), style: TextStyle(color: data.sakitCount > 0 ? Colors.orange.shade800 : Colors.black))),
                DataCell(Text(data.izinCount.toString(), style: TextStyle(color: data.izinCount > 0 ? Colors.blue.shade800 : Colors.black))),
                DataCell(Text(data.alfaCount.toString(), style: TextStyle(color: data.alfaCount > 0 ? Colors.red.shade800 : Colors.black))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class RekapAbsensiView extends StatelessWidget {
  const RekapAbsensiView({super.key});

  @override
  Widget build(BuildContext context) {
    // Inisialisasi controller secara manual karena kita tidak menggunakan GetView
    Get.put(RekapAbsensiController());
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Absensi Siswa'),
        centerTitle: true,
      ),
      // Panggil widget inti kita
      body: const RekapAbsensiWidget(),
    );
  }
}
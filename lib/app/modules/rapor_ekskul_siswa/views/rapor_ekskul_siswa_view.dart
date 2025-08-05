import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/rapor_ekskul_siswa_controller.dart';

class RaporEkskulView extends GetView<RaporEkskulViewController> {
  const RaporEkskulView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pratinjau Rapor Ekskul'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Ekspor ke PDF',
            onPressed: () {
              // Fungsi ekspor PDF akan kita implementasikan selanjutnya
              Get.snackbar("Info", "Fitur Ekspor PDF dalam pengembangan.");
            },
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderRapor(),
              const SizedBox(height: 24),
              _buildTabelEkskul(),
              const SizedBox(height: 24),
              // _buildTabelAbsensi(), // Placeholder
              // const SizedBox(height: 24),
              // _buildCatatanWaliKelas(), // Placeholder
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeaderRapor() {
    final siswa = controller.siswa;
    final homeC = controller.homeC;
    return Column(children: [
      Row(
        children: [
          Expanded(child: _buildInfoItem("Nama", siswa.nama)),
          Expanded(child: _buildInfoItem("Kelas", siswa.namaKelas)),
        ],
      ),
       Row(
        children: [
          Expanded(child: _buildInfoItem("NIS/NISN", siswa.nisn)),
          Expanded(child: _buildInfoItem("Semester", homeC.semesterAktifId.value)),
        ],
      ),
      Row(
        children: [
          Expanded(child: _buildInfoItem("Sekolah", "SD IT UKHUWAH ISLAMIYAH")),
          // Expanded(child: _buildInfoItem("Sekolah", "PKBM SDTQ Telaga Ilmu")),
          Expanded(child: _buildInfoItem("Tahun Ajaran", homeC.idTahunAjaran.value?.replaceAll('-', '/') ?? '')),
        ],
      )
    ]);
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label)),
          const Text(": "),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildTabelEkskul() {
    final daftarNilai = controller.daftarNilaiEkskul;
    return Table(
      border: TableBorder.all(color: Colors.black),
      columnWidths: const {
        0: IntrinsicColumnWidth(), // No
        1: FlexColumnWidth(2),    // Kegiatan
        2: FlexColumnWidth(1),    // Predikat
        3: FlexColumnWidth(4),    // Keterangan
      },
      children: [
        // Header Tabel
        const TableRow(
          decoration: BoxDecoration(color: Colors.grey),
          children: [
            Padding(padding: EdgeInsets.all(8.0), child: Text('No', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.all(8.0), child: Text('Kegiatan Ekstrakurikuler', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.all(8.0), child: Text('Predikat', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.all(8.0), child: Text('Keterangan', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        // Baris Data
        ...daftarNilai.asMap().entries.map((entry) {
          int index = entry.key;
          var item = entry.value;
          return TableRow(
            children: [
              Padding(padding: const EdgeInsets.all(8.0), child: Text('${index + 1}', textAlign: TextAlign.center)),
              Padding(padding: const EdgeInsets.all(8.0), child: Text(item.namaEkskul)),
              Padding(padding: const EdgeInsets.all(8.0), child: Text(item.predikat ?? '-')),
              Padding(padding: const EdgeInsets.all(8.0), child: Text(item.keterangan ?? '-')),
            ],
          );
        }).toList(),
      ],
    );
  }
}
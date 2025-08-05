// File: lib/app/modules/rapor_terpadu/views/rapor_terpadu_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/rapor_siswa_model.dart';
import '../../../models/rapor_terpadu_model.dart';
import '../../../models/rekap_absensi_model.dart';
import '../controllers/rapor_terpadu_controller.dart';
// import '../models/rapor_terpadu_model.dart'; // Impor model kita


class RaporTerpaduView extends GetView<RaporTerpaduController> {
  const RaporTerpaduView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pratinjau Rapor Terpadu'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Ekspor ke PDF',
            onPressed: () => controller.cetakRapor(), // <-- SAMBUNGKAN DI SINI
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.raporLengkap.value == null) {
          return const Center(child: Text("Gagal memuat data rapor."));
        }

        final dataRapor = controller.raporLengkap.value!;

        // Gunakan DefaultTabController untuk mengelola TabBar dan TabBarView
        return DefaultTabController(
          length: 4, // Jumlah tab kita
          child: Column(
            children: [
              // --- Header Informasi Siswa ---
              _buildHeaderSiswa(dataRapor),
              
              // --- TabBar untuk Navigasi ---
              const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: "Akademik"),
                  Tab(text: "Ekstrakurikuler"),
                  Tab(text: "Halaqoh"),
                  Tab(text: "Kehadiran & Catatan"),
                ],
              ),
              
              // --- Konten Tab ---
              Expanded(
                child: TabBarView(
                  children: [
                    _buildTabAkademik(dataRapor.dataAkademik),
                    _buildTabEkskul(dataRapor.dataEkskul),
                    _buildTabHalaqoh(dataRapor.dataHalaqoh),
                    _buildTabLainnya(dataRapor.dataAbsensi, dataRapor.catatanWaliKelas),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // --- WIDGET-WIDGET BUILDER ---

  Widget _buildHeaderSiswa(RaporTerpaduModel data) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Rapor untuk: ${data.dataSiswa.nama}", style: Get.textTheme.titleLarge),
          Text("Kelas: ${data.dataSiswa.namaKelas} | Semester: ${data.semester} | TA: ${data.tahunAjaran}"),
        ],
      ),
    );
  }

  Widget _buildTabAkademik(List<RaporMapelModel> data) {
    if (data.isEmpty) return const Center(child: Text("Data akademik belum diisi."));
    
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final mapel = data[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ExpansionTile(
            leading: CircleAvatar(child: Text(mapel.nilaiAkhir?.toStringAsFixed(0) ?? '-')),
            title: Text(mapel.namaMapel, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Guru: ${mapel.guruPengajar}"),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                // --- LOGIKA TAMPILAN CERDAS DI SINI ---
                child: Builder(
                  builder: (context) {
                    // Prioritas 1: Tampilkan dari ATP/TP jika ada
                    if (mapel.daftarCapaian.isNotEmpty) {
                      return Text(
                        "Capaian: ${mapel.daftarCapaian.map((e) => e.namaUnit).join(', ')}",
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      );
                    }
                    // Prioritas 2: Tampilkan deskripsi manual jika ada
                    else if (mapel.deskripsiCapaian != null && mapel.deskripsiCapaian!.isNotEmpty) {
                      return Text(
                        mapel.deskripsiCapaian!,
                        style: const TextStyle(fontStyle: FontStyle.normal), // Tampilkan normal
                      );
                    }
                    // Prioritas 3: Tampilkan pesan default jika keduanya kosong
                    else {
                      return const Text(
                        "Deskripsi capaian belum diisi oleh guru.",
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                      );
                    }
                  }
                ),
                // --- AKHIR LOGIKA CERDAS ---
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabEkskul(List<RaporEkskulItem> data) {
    if (data.isEmpty) return const Center(child: Text("Siswa tidak terdaftar di ekskul manapun atau nilai belum diisi."));
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final ekskul = data[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.stars, color: Colors.amber),
            title: Text(ekskul.namaEkskul, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(ekskul.keterangan ?? "Keterangan belum diisi."),
            trailing: Chip(label: Text(ekskul.predikat ?? "N/A")),
          ),
        );
      },
    );
  }

  Widget _buildTabHalaqoh(List<RaporHalaqohItem> data) {
    if (data.isEmpty) return const Center(child: Text("Data nilai Halaqoh belum diisi."));
    // Tampilan mirip dengan ekskul
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final halaqoh = data[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.book, color: Colors.green),
            title: Text(halaqoh.jenis, style: const TextStyle(fontWeight: FontWeight.bold)), // "Tahsin" atau "Tahfidz"
            subtitle: Text(halaqoh.keterangan ?? "Keterangan belum diisi."),
            trailing: CircleAvatar(child: Text(halaqoh.nilaiAkhir?.toString() ?? '-')),
          ),
        );
      },
    );
  }

  Widget _buildTabLainnya(RekapAbsensiSiswaModel absensi, String catatan) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Bagian Absensi ---
          const Text("Rekapitulasi Kehadiran (KBM)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAbsensiItem("Sakit", absensi.sakitCount, Colors.orange),
                  _buildAbsensiItem("Izin", absensi.izinCount, Colors.blue),
                  _buildAbsensiItem("Alfa", absensi.alfaCount, Colors.red),
                ],
              ),
            ),
          ),
          const Divider(height: 32),
          // --- Bagian Catatan Wali Kelas ---
          const Text("Catatan Wali Kelas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              catatan.isEmpty ? "Tidak ada catatan." : catatan,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsensiItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(count.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label),
      ],
    );
  }
}
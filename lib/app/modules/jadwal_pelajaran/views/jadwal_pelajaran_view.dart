// views/jadwal_pelajaran_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/jadwal_pelajaran_controller.dart';

class JadwalPelajaranView extends GetView<JadwalPelajaranController> {
  const JadwalPelajaranView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Pelajaran'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- DROPDOWN UNTUK MEMILIH KELAS ---
            Obx(() => DropdownButtonFormField<String>(
                  value: controller.selectedKelasId.value,
                  hint: const Text('Pilih Kelas'),
                  decoration: const InputDecoration(
                    labelText: 'Tampilkan Jadwal Untuk Kelas',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    prefixIcon: Icon(Icons.class_),
                  ),
                  items: controller.daftarKelas.map((kelas) {
                    return DropdownMenuItem<String>(
                      value: kelas['id'] as String,
                      child: Text(kelas['nama'] as String),
                    );
                  }).toList(),
                  onChanged: controller.onKelasChanged,
                )),
            const SizedBox(height: 16),
            
            // --- Tampilan Jadwal (hanya muncul setelah kelas dipilih) ---
            Obx(() {
              if (controller.selectedKelasId.value == null) {
                return const Expanded(child: Center(child: Text('Silakan pilih kelas untuk melihat jadwal.')));
              }
              if (controller.isLoading.value) {
                return const Expanded(child: Center(child: CircularProgressIndicator()));
              }
              // Cek jika ada error atau jadwal kosong setelah loading selesai
              bool isDataEmpty = controller.jadwalPelajaranPerHari.values.every((list) => list.isEmpty);
              if (controller.errorMessage.value.isNotEmpty && isDataEmpty) {
                return Expanded(child: Center(child: Text(controller.errorMessage.value, textAlign: TextAlign.center)));
              }
              
              // Tampilkan Tab Controller jika semua kondisi terpenuhi
              return Expanded(
                child: DefaultTabController(
                  length: controller.daftarHari.length,
                  child: Column(
                    children: [
                      TabBar(
                        isScrollable: true,
                        tabs: controller.daftarHari.map((String hari) => Tab(text: hari)).toList(),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: controller.daftarHari.map((String hari) {
                            return _buildScheduleList(context, hari);
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // WIDGET BARU: Tampilan daftar jadwal yang keren dan futuristik
  Widget _buildScheduleList(BuildContext context, String hari) {
    // Variabel ini tetap di sini, ini adalah sumber datanya
    final RxList<Map<String, dynamic>> pelajaranHariIni = controller.jadwalPelajaranPerHari[hari]!;

    return Obx(() {
      if (pelajaranHariIni.isEmpty) {
        return const Center(child: Text('Tidak ada jadwal untuk hari ini.'));
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        itemCount: pelajaranHariIni.length,
        itemBuilder: (context, index) {
          // 'pelajaran' didefinisikan DI DALAM builder, untuk setiap item
          final pelajaran = pelajaranHariIni[index];

          // [FIX] DEKLARASIKAN SEMUA VARIABEL YANG BERASAL DARI 'pelajaran' DI SINI
          final String mapel = pelajaran['mapel'] as String? ?? 'Tanpa Nama';
          final String mulai = pelajaran['mulai'] as String? ?? '--:--';
          final String selesai = pelajaran['selesai'] as String? ?? '--:--';
          final int jamKe = pelajaran['jamKe'] as int? ?? 0;
          final String guru = pelajaran['guru'] as String? ?? 'Guru Belum Ditentukan'; // <-- POSISI YANG BENAR

          // Sekarang, semua variabel aman untuk digunakan di dalam Container ini
          return Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Colors.purple.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15.0),
              border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // --- Bagian Kiri (Waktu) ---
                  Container(
                    width: 90,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        bottomLeft: Radius.circular(15),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(mulai, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text("s/d", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(selesai, style: const TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  ),
                  // --- Bagian Kanan (Detail Mapel) ---
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            mapel,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // [TAMBAHAN] Tampilkan nama guru
                          Text(
                            guru,
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Chip(
                            label: Text('Jam ke-$jamKe'),
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}
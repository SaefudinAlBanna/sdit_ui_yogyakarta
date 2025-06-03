// views/jadwal_pelajaran_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/jadwal_pelajaran_controller.dart';

class JadwalPelajaranView extends GetView<JadwalPelajaranController> {
  const JadwalPelajaranView({super.key});

  @override
  Widget build(BuildContext context) {
    // Jika Anda tidak menggunakan Get.put() di binding atau route,
    // Anda mungkin perlu menginisialisasi controller di sini.
    // Namun, dengan binding, ini sudah dihandle.
    // final JadwalPelajaranController c = Get.put(JadwalPelajaranController()); // Jika tidak ada binding

    return DefaultTabController(
      length: controller.daftarHari.length, // Jumlah tab sesuai jumlah hari
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Jadwal Pelajaran'),
          centerTitle: true,
          actions: [
            // Tombol Refresh
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                controller.refreshJadwal();
              },
            ),
          ],
          bottom: TabBar(
            isScrollable: true, // Agar bisa di-scroll jika banyak hari
            tabs: controller.daftarHari.map((String hari) {
              return Tab(text: hari);
            }).toList(),
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.errorMessage.value.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            );
          }

          // Cek apakah ada data pelajaran sama sekali
          bool isDataEmpty = controller.jadwalPelajaranPerHari.values.every((list) => list.isEmpty);
          if (isDataEmpty && controller.errorMessage.value.isEmpty) {
             return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Belum ada jadwal pelajaran yang tersimpan untuk tahun ajaran ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          return TabBarView(
            children: controller.daftarHari.map((String hari) {
              // Dapatkan RxList pelajaran untuk hari ini
              final RxList<Map<String, dynamic>> pelajaranHariIni =
                  controller.jadwalPelajaranPerHari[hari] ?? RxList<Map<String, dynamic>>([]);

              // Dengarkan perubahan pada RxList ini
              return Obx(() {
                if (pelajaranHariIni.isEmpty) {
                  return Center(
                    child: Text('Tidak ada jadwal untuk hari $hari.'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: pelajaranHariIni.length,
                  itemBuilder: (context, index) {
                    final pelajaran = pelajaranHariIni[index];
                    final String mapel = pelajaran['mapel'] as String? ?? 'N/A';
                    final String mulai = pelajaran['mulai'] as String? ?? '--:--';
                    final String selesai = pelajaran['selesai'] as String? ?? '--:--';
                    final int jamKe = pelajaran['jamKe'] as int? ?? 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                      elevation: 2.0,
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(jamKe.toString()),
                        ),
                        title: Text(
                          mapel,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Jam: $mulai - $selesai'),
                        // Tambahkan detail lain jika perlu
                      ),
                    );
                  },
                );
              });
            }).toList(),
          );
        }),
      ),
    );
  }
}

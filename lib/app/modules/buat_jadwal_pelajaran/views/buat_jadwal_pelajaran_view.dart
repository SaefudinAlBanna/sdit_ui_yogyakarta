import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/buat_jadwal_pelajaran_controller.dart';

class BuatJadwalPelajaranView extends GetView<BuatJadwalPelajaranController> {
  const BuatJadwalPelajaranView({super.key});

  @override
  Widget build(BuildContext context) {
    // Inisialisasi controller jika belum ada (misalnya saat halaman pertama kali dibuka)
    // Get.put(BuatJadwalPelajaranController()); // Atau lakukan di binding

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Jadwal Pelajaran'),
        centerTitle: true,
        actions: [
          Obx(() => controller.isLoading.value
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
              : IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () {
                    controller.simpanJadwalKeFirestore();
                  },
                )),
           IconButton( // Tombol Load
            icon: const Icon(Icons.download),
            tooltip: "Muat Jadwal",
            onPressed: () {
              controller.loadJadwalFromFirestore();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown untuk memilih hari
            Obx(() => DropdownButtonFormField<String>(
                  value: controller.selectedHari.value,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Hari',
                    border: OutlineInputBorder(),
                  ),
                  items: controller.daftarHari.map((String hari) {
                    return DropdownMenuItem<String>(
                      value: hari,
                      child: Text(hari),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    controller.changeSelectedHari(newValue);
                  },
                )),
            const SizedBox(height: 20),

            // Judul untuk daftar pelajaran hari ini
            Obx(() => Text(
                  'Jadwal untuk: ${controller.selectedHari.value}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                )),
            const SizedBox(height: 10),

            // Daftar pelajaran untuk hari yang dipilih
            Expanded(
              child: Obx(() {
                // Pastikan list untuk hari yang dipilih ada
                final listPelajaranHariIni =
                    controller.jadwalPelajaran[controller.selectedHari.value];
                if (listPelajaranHariIni == null || listPelajaranHariIni.isEmpty) {
                  return const Center(child: Text('Belum ada pelajaran. Klik tombol + untuk menambah.'));
                }
                return ListView.builder(
                  itemCount: listPelajaranHariIni.length,
                  itemBuilder: (context, index) {
                    final pelajaran = listPelajaranHariIni[index];
                    // Buat TextEditingController sementara untuk setiap field
                    // agar bisa update on-the-fly tanpa harus submit form
                    // dan agar nilai tetap saat rebuild widget (misal saat hapus item lain)
                    // Namun, ini akan lebih kompleks jika banyak field.
                    // Untuk simple, kita bisa update langsung ke controller.
                    // Untuk mapel, kita gunakan TextFormField dengan onChanged.
                    // Untuk waktu, kita gunakan TextButton yang memanggil time picker.

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Jam ke-${pelajaran['jamKe']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    controller.hapusPelajaran(index);
                                  },
                                ),
                              ],
                            ),
                            TextFormField(
                              initialValue: pelajaran['mapel'] as String?,
                              decoration: const InputDecoration(labelText: 'Mata Pelajaran'),
                              onChanged: (value) {
                                // Langsung update ke controller saat teks berubah
                                controller.updatePelajaranDetail(index, 'mapel', value);
                              },
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      controller.pilihWaktu(context, index, 'mulai');
                                    },
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Jam Mulai',
                                        border: InputBorder.none, // Hilangkan border default
                                      ),
                                      child: Text(
                                        pelajaran['mulai'] as String? ?? 'Pilih Waktu',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: (pelajaran['mulai'] as String?) == '00:00' || (pelajaran['mulai'] as String?) == null || (pelajaran['mulai'] as String?)!.isEmpty
                                              ? Colors.grey
                                              : Theme.of(context).textTheme.titleMedium?.color,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      controller.pilihWaktu(context, index, 'selesai');
                                    },
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Jam Selesai',
                                        border: InputBorder.none,
                                      ),
                                      child: Text(
                                        pelajaran['selesai'] as String? ?? 'Pilih Waktu',
                                         style: TextStyle(
                                          fontSize: 16,
                                          color: (pelajaran['selesai'] as String?) == '00:00' || (pelajaran['selesai'] as String?) == null || (pelajaran['selesai'] as String?)!.isEmpty
                                              ? Colors.grey
                                              : Theme.of(context).textTheme.titleMedium?.color,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.tambahPelajaran();
        },
        child: const Icon(Icons.add),
        tooltip: 'Tambah Pelajaran',
      ),
    );
  }
}
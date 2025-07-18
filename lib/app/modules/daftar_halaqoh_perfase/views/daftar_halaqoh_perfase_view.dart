import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../controllers/daftar_halaqoh_perfase_controller.dart';

class DaftarHalaqohPerfaseView extends GetView<DaftarHalaqohPerfaseController> {
  const DaftarHalaqohPerfaseView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Halaqoh'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- DROPDOWN UNTUK MEMILIH FASE ---
            Obx(() => DropdownButtonFormField<String>(
                  value: controller.selectedFase.value,
                  hint: const Text("Pilih Fase Halaqoh..."),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: controller.listPilihanFase.map((String fase) {
                    return DropdownMenuItem<String>(
                      value: fase,
                      child: Text("Fase $fase"),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    // Panggil method di controller saat pilihan berubah
                    controller.onFaseChanged(newValue);
                  },
                )),
            const SizedBox(height: 20),

            // --- AREA KONTEN YANG REAKTIF ---
            // Expanded memastikan ListView mengisi sisa ruang yang tersedia
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Jika belum ada fase yang dipilih
                if (controller.selectedFase.value == null) {
                  return const Center(
                    child: Text(
                      'Silakan pilih fase terlebih dahulu.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                // Jika data untuk fase yang dipilih ternyata kosong
                if (controller.daftarPengampu.isEmpty) {
                  return Center(
                    child: Text(
                      'Tidak ada kelompok pengampu di Fase ${controller.selectedFase.value}.',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                // Jika data ada, bangun ListView
                return ListView.separated(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: controller.daftarPengampu.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 4), // Jarak antar card
                  itemBuilder: (context, index) {
                    final pengampu = controller.daftarPengampu[index];

                    // Gunakan Material untuk ripple effect yang lebih terkontrol
                    return Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        // onTap: () {
                        //   // Aksi navigasi Anda (kode ini sudah benar)
                        //   final faseEncoded = Uri.encodeComponent(pengampu.fase);
                        //   final namaPengampuEncoded = Uri.encodeComponent(pengampu.namaPengampu);
                        //   final idPengampuEncoded = Uri.encodeComponent(pengampu.idPengampu);
                        //   Get.toNamed(
                        //     '${Routes.DAFTAR_HALAQOHNYA}/$faseEncoded/$namaPengampuEncoded/$idPengampuEncoded',
                        //   );
                        // },
                        onTap: () {
                            // Mengirim argumen sebagai Map agar lebih mudah dikelola
                            Get.toNamed(
                              Routes.DAFTAR_HALAQOHNYA, // Cukup panggil nama route-nya
                              arguments: {
                                'fase': pengampu.fase,
                                'namapengampu': pengampu.namaPengampu,
                                'idpengampu': pengampu.idPengampu,
                                'namatempat': pengampu.namaTempat, // <-- INI YANG PALING PENTING
                              },
                            );
                          },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          child: Row(
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: pengampu.profileImageUrl != null
                                    ? NetworkImage(pengampu.profileImageUrl!)
                                    : null,
                                child: pengampu.profileImageUrl == null
                                    ? Text(
                                        pengampu.namaPengampu.isNotEmpty ? pengampu.namaPengampu[0] : 'P',
                                        style: const TextStyle(fontSize: 24, color: Colors.grey),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              // Nama Pengampu
                              Expanded(
                                child: Text(
                                  pengampu.namaPengampu,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Informasi Jumlah Siswa (SANGAT INFORMATIF)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    pengampu.jumlahSiswa.toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  const Text(
                                    "Siswa",
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
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
    );
  }
}
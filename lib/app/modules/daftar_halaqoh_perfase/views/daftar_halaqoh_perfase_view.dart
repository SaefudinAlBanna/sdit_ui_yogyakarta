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
        title: const Text('Pantauan Halaqoh per Fase'),
        centerTitle: true,
        actions: [
          // Bungkus semua actions dengan Obx agar reaktif
          Obx(() {
            return Row(
              children: [
                // Tombol untuk MENGATUR PENGGANTI
                if (controller.homeController.canEditOrDeleteHalaqoh || controller.homeController.isAdminKepsek)
                  IconButton(
                    icon: const Icon(Icons.swap_horiz_rounded),
                    tooltip: 'Atur Pengganti Halaqoh',
                    onPressed: () {
                      Get.toNamed(Routes.ATUR_PENGGANTI); // Perlu binding
                    },
                  ),

                // Tombol untuk MENAMBAH KELOMPOK BARU
                if (controller.homeController.canEditOrDeleteHalaqoh)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Buat Kelompok Halaqoh Baru',
                    onPressed: () {
                      Get.toNamed(Routes.TAMBAH_KELOMPOK_MENGAJI); // Perlu binding
                    },
                  ),
              ],
            );
          }),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFaseSelector(),
            const SizedBox(height: 16),
            
            // --- FITUR BARU: TEXTFIELD PENCARIAN ---
            Obx(() => TextField(
              controller: controller.searchC,
              onChanged: (value) => controller.searchQuery.value = value,
              enabled: controller.selectedFase.value != null, // Aktif jika fase sudah dipilih
              decoration: InputDecoration(
                hintText: 'Cari nama pengampu...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            )),
            const SizedBox(height: 16),
            
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.selectedFase.value == null) {
                  return const Center(child: Text('Silakan pilih fase terlebih dahulu.'));
                }
                if (controller.daftarPengampuFiltered.isEmpty) {
                  return Center(child: Text('Tidak ada kelompok pengampu di Fase ${controller.selectedFase.value}.'));
                }
                
                return ListView.builder(
                  itemCount: controller.daftarPengampuFiltered.length,
                  itemBuilder: (context, index) {
                    final pengampu = controller.daftarPengampuFiltered[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Get.toNamed(Routes.DAFTAR_HALAQOHNYA, arguments: {
                          'fase': pengampu.fase, 'namapengampu': pengampu.namaPengampu,
                          'idpengampu': pengampu.idPengampu, 'namatempat': pengampu.namaTempat,
                        }),                   
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.grey.shade200, // Warna latar jika tidak ada gambar
                                    // Gunakan NetworkImage jika URL tersedia
                                    backgroundImage: pengampu.profileImageUrl != null
                                        ? NetworkImage(pengampu.profileImageUrl!)
                                        : null,
                                    // Tampilkan initial nama HANYA jika tidak ada gambar
                                    child: pengampu.profileImageUrl == null
                                        ? Text(
                                            // Safety check: pastikan nama tidak kosong sebelum mengambil initial
                                            pengampu.namaPengampu.isNotEmpty ? pengampu.namaPengampu[0].toUpperCase() : 'P',
                                            style: const TextStyle(fontSize: 24, color: Colors.grey),
                                          )
                                        : null, // Jangan tampilkan apa-apa jika ada gambar
                                  ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(pengampu.namaPengampu, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                    const SizedBox(height: 4),
                                    // --- FITUR BARU: TAMPILKAN STATUS SIAP UJIAN ---
                                    if (pengampu.jumlahSiapUjian > 0)
                                      Chip(
                                        avatar: Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                                        label: Text("${pengampu.jumlahSiapUjian} Siap Ujian", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        backgroundColor: Colors.green.shade100,
                                        padding: EdgeInsets.zero,
                                      )
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                children: [
                                  Text(pengampu.jumlahSiswa.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).primaryColor)),
                                  const Text("Siswa", style: TextStyle(fontSize: 12, color: Colors.grey)),
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

  Widget _buildFaseSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Pilih Fase Halaqoh",
            style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: controller.listPilihanFase.map((fase) {
              final isSelected = controller.selectedFase.value == fase;
              final namaDokumenFase = "Fase $fase";
              
              // [BARU] Bungkus dengan Row agar bisa menambahkan tombol
              return Row(
                children: [
                  ChoiceChip(
                    label: Text("Fase $fase"),
                    avatar: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) controller.onFaseChanged(fase);
                    },
                    selectedColor: Colors.teal.shade500,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  
                  // [BARU] Tombol migrasi khusus Super Admin
                  // if (controller.homeController.isDalang || controller.homeController.kapten)
                  if (controller.homeController.isDalang)
                    IconButton(
                      icon: const Icon(Icons.cleaning_services_rounded),
                      tooltip: "Perbaiki data shortcut siswa di Fase $fase",
                      color: Colors.blueGrey,
                      onPressed: () {
                        Get.defaultDialog(
                          title: "Konfirmasi Migrasi",
                          middleText: "Anda akan memperbaiki semua data shortcut siswa di $namaDokumenFase. Proses ini tidak bisa dibatalkan. Lanjutkan?",
                          textConfirm: "Ya, Lanjutkan",
                          textCancel: "Batal",
                          onConfirm: () {
                            Get.back();
                            controller.migrasiDataShortcutSiswaPerFase(namaDokumenFase);
                          }
                        );
                      },
                    ),
                ],
              );
            }).toList(),
          )),
        ],
      ),
    );
  }
}


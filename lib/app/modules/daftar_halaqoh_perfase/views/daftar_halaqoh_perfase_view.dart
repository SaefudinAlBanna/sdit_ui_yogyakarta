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
          if(controller.homeController.tambahHalaqohFase)
          IconButton(
            onPressed: (){
            Get.toNamed(Routes.TAMBAH_KELOMPOK_MENGAJI);
            },
            icon: const Icon(Icons.add))
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
                              CircleAvatar( /* ... (Avatar tidak berubah) ... */ ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0), // Padding horizontal
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Pilih Fase Halaqoh",
            style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Obx untuk merebuild chip saat pilihan berubah
          Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, // Agar chip terdistribusi rata
            children: controller.listPilihanFase.map((fase) {
              final isSelected = controller.selectedFase.value == fase;
              return ChoiceChip(
                label: Text("Fase $fase"),
                avatar: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    // Panggil fungsi di controller seperti sebelumnya
                    controller.onFaseChanged(fase);
                  }
                },
                selectedColor: Colors.teal.shade500, // Warna bisa disesuaikan
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              );
            }).toList(),
          )),
        ],
      ),
    );
  }
}


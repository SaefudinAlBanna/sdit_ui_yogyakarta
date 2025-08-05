import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/siswa_model.dart';
import '../controllers/instance_ekskul_controller.dart';

class KelolaAnggotaView extends GetView<InstanceEkskulController> {
  final String instanceEkskulId;
  const KelolaAnggotaView({super.key, required this.instanceEkskulId});

  @override
  Widget build(BuildContext context) {
    // Controller untuk text field pencarian
    final searchC = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Anggota Ekskul'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Obx(() => DropdownButtonFormField<String>(
                  value: controller.filterKelas.value,
                  hint: const Text('Filter Berdasarkan Kelas'),
                  isExpanded: true,
                  items: controller.semuaKelas.isEmpty
                      ? []
                      : [
                          const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Tampilkan Semua Kelas')),
                          ...controller.semuaKelas.map((kelas) =>
                              DropdownMenuItem(value: kelas, child: Text(kelas))),
                        ],
                  // Gunakan fungsi yang sudah kita buat di controller
                  onChanged: (value) => controller.changeKelasFilter(value),
                )),
          ),
          // --- WIDGET PENCARIAN BARU ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextFormField(
              controller: searchC,
              onChanged: (value) {
                controller.searchQuery.value = value;
              },
              decoration: InputDecoration(
                labelText: 'Cari Nama Siswa...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchC.clear();
                          controller.searchQuery.value = '';
                        },
                      )
                    : const SizedBox.shrink()),
              ),
            ),
          ),
          const Divider(height: 1),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              "Centang untuk menambah anggota, hilangkan centang untuk mengeluarkan.",
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ),
          
          // --- DAFTAR SISWA REAKTIF ---
          Expanded(
            child: Obx(() {
              if (controller.isLoadingSiswa.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // --- LOGIKA PENYARINGAN GANDA ---
              List<SiswaModel> filteredList = controller.semuaSiswa;

              // 1. Filter berdasarkan kelas (jika ada)
              if (controller.filterKelas.value != null) {
                filteredList = filteredList
                    .where((s) => s.namaKelas == controller.filterKelas.value)
                    .toList();
              }

              // 2. Filter berdasarkan pencarian (jika ada)
              if (controller.searchQuery.value.isNotEmpty) {
                filteredList = filteredList
                    .where((s) => s.nama.toLowerCase().contains(controller.searchQuery.value.toLowerCase()))
                    .toList();
              }
              // --- AKHIR LOGIKA PENYARINGAN ---

              if (filteredList.isEmpty) {
                return const Center(child: Text('Tidak ada siswa yang cocok.'));
              }

              return ListView.builder(
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final siswa = filteredList[index];
                  return Obx(() => CheckboxListTile(
                        title: Text(siswa.nama),
                        subtitle: Text("NISN: ${siswa.nisn} | Kelas: ${siswa.namaKelas}"),
                        value: controller.anggotaTerpilih.any((terpilih) => terpilih.nisn == siswa.nisn),
                        onChanged: (isSelected) {
                          if (isSelected!) {
                            controller.anggotaTerpilih.add(siswa);
                          } else {
                            controller.anggotaTerpilih.removeWhere((terpilih) => terpilih.nisn == siswa.nisn);
                          }
                        },
                      ));
                },
              );
            }),
          ),
        ],
      ),
      // Tombol Simpan di bagian bawah layar
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() => ElevatedButton( // <-- Bungkus dengan Obx
          // Panggil fungsi yang baru kita buat
          onPressed: controller.isLoadingSiswa.value 
              ? null // Nonaktifkan tombol saat menyimpan
              : () => controller.updateKeanggotaan(instanceEkskulId),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.green,
            disabledBackgroundColor: Colors.grey,
          ),
          child: controller.isLoadingSiswa.value
              ? const CircularProgressIndicator(color: Colors.white)
              : Text('Simpan (${controller.anggotaTerpilih.length} Anggota Terpilih)'),
        )),
      ),
    );
  }
}
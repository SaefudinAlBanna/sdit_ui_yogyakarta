// lib/app/modules/daftar_siswa_permapel/views/daftar_siswa_permapel_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../../models/siswa_model.dart';
import '../../../routes/app_pages.dart';
import '../../input_nilai_siswa/bindings/input_nilai_siswa_binding.dart';
import '../../input_nilai_siswa/views/input_nilai_siswa_view.dart';
import '../../rapor_siswa/bindings/rapor_siswa_binding.dart';
import '../../rapor_siswa/views/rapor_siswa_view.dart';
import '../controllers/daftar_siswa_permapel_controller.dart';

class DaftarSiswaPermapelView extends GetView<DaftarSiswaPermapelController> {
  const DaftarSiswaPermapelView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.appBarTitle.value)),
        centerTitle: true,
        actions: [
          // Tambahkan tombol baru di sini jika pengguna adalah Wali Kelas
          Obx(() {
            if (controller.isWaliKelas.value) {
              return IconButton(
                icon: const Icon(Icons.edit_document),
                tooltip: 'Kelola Catatan Rapor',
                onPressed: () {
                  Get.toNamed(
                    Routes.KELOLA_CATATAN_RAPOR,
                    arguments: controller.idKelas, // Kirim idKelas
                  );
                },
              );
            }
            return const SizedBox.shrink();
          }),

          PopupMenuButton<String>(
            icon: const Icon(Icons.add_task_rounded),
            tooltip: "Menu Tugas & Penilaian",
            onSelected: (value) {
              if (value == 'buat_tugas') _showBuatTugasDialog(context);
              if (value == 'input_nilai') _showInputNilaiMassalSheet(context);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'buat_tugas', child: ListTile(leading: Icon(Icons.note_add_outlined), title: Text("Buat Tugas/Ulangan Baru"))),
              const PopupMenuItem(value: 'input_nilai', child: ListTile(leading: Icon(Icons.grading_rounded), title: Text("Input Nilai Massal"))),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (controller.daftarSiswa.isEmpty) return const Center(child: Text("Belum ada siswa di kelas ini."));
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          itemCount: controller.daftarSiswa.length,
          itemBuilder: (context, index) {
            final siswa = controller.daftarSiswa[index];
            return _SiswaCard(siswa: siswa);
          },
        );
      }),
    );
  }

  // --- DIALOG UNTUK MEMBUAT TUGAS BARU ---
  void _showBuatTugasDialog(BuildContext context) {
    final theme = Theme.of(context);
    controller.judulTugasC.clear();
    controller.deskripsiTugasC.clear();
    
    Get.defaultDialog(
      title: "Buat Tugas / Ulangan Baru",
      content: Column(
        children: [
          TextField(controller: controller.judulTugasC, decoration: const InputDecoration(labelText: 'Judul (Contoh: PR Bab 1)')),
          const SizedBox(height: 12),
          TextField(controller: controller.deskripsiTugasC, decoration: const InputDecoration(labelText: 'Deskripsi (Opsional)'), maxLines: 3),
        ],
      ),
      actions: [
        OutlinedButton(onPressed: () => controller.buatTugasBaru("Ulangan Harian"), child: const Text("Simpan Ulangan")),
        ElevatedButton(onPressed: () => controller.buatTugasBaru("PR"), child: const Text("Simpan PR")),
      ],
    );
  }

  // --- BOTTOMSHEET UNTUK INPUT NILAI MASSAL ---
  void _showInputNilaiMassalSheet(BuildContext context) {
  final theme = Theme.of(context);
  // Reset state sebelum bottom sheet dibuka
  controller.tugasTerpilihId.value = null;
  controller.catatanNilaiC.clear();
  controller.siswaTerpilihUntukNilai.clear();
  controller.nilaiIndividualControllers.forEach((_, c) => c.clear());

  Get.bottomSheet(
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    Container(
      // Gunakan sebagian besar layar, tapi beri sedikit ruang di atas
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Gunakan SafeArea untuk menghindari notch/statusbar
      child: SafeArea(
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Dropdown untuk memilih tugas
            DropdownSearch<Map<String, dynamic>>(
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: "Cari tugas...",
                  ),
                ),
              ),
              items: (f, cs) => controller.getTugasUntukDinilai(),
              itemAsString: (item) => "[${item['kategori']}] ${item['judul']}",
              onChanged: (item) => controller.tugasTerpilihId.value = item?['id'],
              compareFn: (item, selectedItem) => item['id'] == selectedItem['id'],
              decoratorProps: const DropDownDecoratorProps(
                decoration: InputDecoration(
                  labelText: "Pilih Tugas/Ulangan yang Akan Dinilai",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Catatan umum
            TextField(
              controller: controller.catatanNilaiC,
              decoration: const InputDecoration(
                labelText: 'Catatan (Opsional, berlaku untuk semua)',
                border: OutlineInputBorder(),
              ),
            ),
            const Divider(height: 24),
            Text("Pilih Siswa & Input Nilai", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Daftar siswa
            Expanded(
              child: Obx(
                () => ListView.builder(
                  itemCount: controller.daftarSiswa.length,
                  itemBuilder: (ctx, index) {
                    final siswa = controller.daftarSiswa[index];
                    final nisn = siswa['idSiswa'] as String;
                    final nilaiController = controller.nilaiIndividualControllers[nisn];

                    if (nilaiController == null) {
                      // Safety check, seharusnya tidak pernah terjadi
                      return const SizedBox.shrink();
                    }

                    return Obx(
                      () => CheckboxListTile(
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(siswa['namasiswa']),
                        value: controller.siswaTerpilihUntukNilai.contains(nisn),
                        onChanged: (val) => controller.toggleSiswaSelection(nisn),
                        secondary: SizedBox(
                          width: 80,
                          child: TextField(
                            controller: nilaiController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: 'Nilai',
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              child: Obx(
                () => ElevatedButton.icon(
                  icon: controller.isDialogLoading.value ? const SizedBox.shrink() : const Icon(Icons.save),
                  label: controller.isDialogLoading.value 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text("Simpan untuk Siswa Terpilih"),
                  onPressed: controller.isDialogLoading.value ? null : controller.simpanNilaiMassal,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class _SiswaCard extends StatelessWidget {
  final Map<String, dynamic> siswa;
  final DaftarSiswaPermapelController controller = Get.find();

  _SiswaCard({required this.siswa, super.key});

  @override
  Widget build(BuildContext context) {
    final String namaSiswa = siswa['namasiswa'] ?? 'Nama tidak ada';
    final String nis = siswa['nisn'] ?? 'NISN tidak ada';
    final String idSiswa = siswa['idSiswa'];
    final dynamic nilaiAkhirRaw = siswa['nilai_akhir'];
    String nilaiAkhirFormatted;
    if (nilaiAkhirRaw is num) {
      // Jika tipe datanya angka, format menjadi 2 desimal
      nilaiAkhirFormatted = nilaiAkhirRaw.toStringAsFixed(2);
    } else {
      nilaiAkhirFormatted = '-';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: (){
          Get.to(
                () => InputNilaiSiswaView(),
                binding: InputNilaiSiswaBinding(),
                arguments: {
                  'idKelas': controller.idKelas,
                  'idMapel': controller.namaMapel,
                  'idSiswa': idSiswa,
                  'namaSiswa': namaSiswa,
                },
              );
        },
        // Avatar di sebelah kiri
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Text(
            namaSiswa.isNotEmpty ? namaSiswa[0].toUpperCase() : 'S',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
        ),
        // Nama dan NIS di tengah
        title: Text(namaSiswa, style: const TextStyle(fontWeight: FontWeight.bold)),
        
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("NISN: $nis", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
             Text("Nilai Akhir: $nilaiAkhirFormatted", 
          style: TextStyle(
            fontWeight: FontWeight.w600, 
            color: Colors.blue.shade800, fontSize: 12
          )),
          ],
        ),
        
        // trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        trailing: Obx(() {
          if (controller.isWaliKelas.value) {
            return PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'rapor_akademik') {
                  // --- INI ADALAH RAPOR LAMA (JANGAN DIHAPUS) ---
                  Get.toNamed(
                    Routes.RAPOR_SISWA,
                    arguments: {
                      'idSiswa': idSiswa,
                      'namaSiswa': namaSiswa,
                      'idKelas': controller.idKelas,
                    },
                  );
                } else if (value == 'rapor_terpadu') {
                  // --- INI TOMBOL BARU KITA ---
                  // Kita butuh objek SiswaModel lengkap untuk dikirim
                  final siswaModel = SiswaModel(
                    nisn: nis,
                    nama: namaSiswa,
                    idKelas: controller.idKelas,
                    namaKelas: controller.idKelas, // Atau dari field lain jika ada
                  );
                  Get.toNamed(
                    Routes.RAPOR_TERPADU, // Pastikan rute ini sudah dibuat
                    arguments: siswaModel,
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'rapor_akademik',
                  child: ListTile(leading: Icon(Icons.assessment_outlined), title: Text('Rapor Akademik')),
                ),
                // --- MENU BARU KITA ---
                const PopupMenuItem(
                  value: 'rapor_terpadu',
                  child: ListTile(leading: Icon(Icons.auto_stories), title: Text('Rapor Terpadu')),
                ),
                // ---------------------
                const PopupMenuItem(
                  value: 'profil',
                  child: ListTile(leading: Icon(Icons.person_outline), title: Text('Profil Siswa')),
                ),
              ],
            );
          } else {
            return const Icon(Icons.chevron_right, color: Colors.grey);
          }
        }),
        contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      ),
    );
  }
}

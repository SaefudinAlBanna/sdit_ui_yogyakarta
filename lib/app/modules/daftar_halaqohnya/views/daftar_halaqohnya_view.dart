// lib/app/modules/daftar_halaqohnya/views/daftar_halaqohnya_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../../models/siswa_halaqoh.dart';
import '../controllers/daftar_halaqohnya_controller.dart';
import '../../../routes/app_pages.dart';

class DaftarHalaqohnyaView extends GetView<DaftarHalaqohnyaController> {
  const DaftarHalaqohnyaView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(controller.fase, style: const TextStyle(fontSize: 18)),
            Text(controller.namaPengampu, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
          ],
        ),
        centerTitle: true,
          actions: [
            // --- [LENGKAP] Tombol Aksi untuk Koordinator ---
            Obx(() => controller.daftarSiswa.isEmpty
              ? const SizedBox.shrink() // Sembunyikan jika tidak ada siswa
              : PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  tooltip: "Menu Aksi",
                  onSelected: (value) {
                    if (value == 'input_nilai') _showInputNilaiMassalSheet(context);
                    if (value == 'update_umi') _showBulkUpdateDialog();
                    if (value == 'tambah_siswa') _showPilihKelasDialog();
                    if (value == 'tandai_ujian') _showTandaiUjianSheet(context);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'tandai_ujian', child: ListTile(leading: Icon(Icons.assignment_turned_in_outlined), title: Text('Tandai Siap Ujian'))),
                    const PopupMenuItem(value: 'input_nilai', child: ListTile(leading: Icon(Icons.edit_note), title: Text('Input Nilai Massal'))),
                    const PopupMenuItem(value: 'update_umi', child: ListTile(leading: Icon(Icons.group_work_outlined), title: Text('Update UMI Massal'))),
                    const PopupMenuItem(value: 'tambah_siswa', child: ListTile(leading: Icon(Icons.person_add_alt_1), title: Text('Tambah Siswa'))),
                  ],
                ),
            )
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.daftarSiswa.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: controller.daftarSiswa.length,
            itemBuilder: (context, index) {
              final siswa = controller.daftarSiswa[index];
              return _buildSiswaCard(siswa);
            },
          );
        }),
      );
  }

  // Di dalam file: lib/app/modules/daftar_halaqohnya/views/daftar_halaqohnya_view.dart

  // --- FUNGSI BARU UNTUK MENAMPILKAN BOTTOM SHEET UJIAN (VERSI LENGKAP & FINAL) ---
  void _showTandaiUjianSheet(BuildContext context) {
    final theme = Theme.of(context);
    controller.santriTerpilihUntukUjian.clear();
    controller.capaianUjianC.clear();
    controller.levelUjianC.clear();

    Get.bottomSheet(
      Container( // Widget utama untuk bottom sheet
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // --- [LENGKAP] Handle drag ---
            Container(
              margin: const EdgeInsets.only(bottom: 16), // Memberi jarak ke konten di bawahnya
              width: 50,                                // Lebar handle
              height: 5,                                // Tinggi handle
              decoration: BoxDecoration(
                color: Colors.grey[300],                // Warna handle
                borderRadius: BorderRadius.circular(10), // Membuat sudutnya melengkung
              ),
            ),
            // -----------------------------
            
            Expanded(
              child: ListView(
                children: [
                  Text("1. Isi Detail Ujian", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(controller: controller.levelUjianC, decoration: const InputDecoration(labelText: 'Level Ujian (Contoh: Jilid 1, Juz 30)', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: controller.capaianUjianC, decoration: const InputDecoration(labelText: 'Capaian Terakhir Santri', border: OutlineInputBorder()), maxLines: 3),
                  const SizedBox(height: 24),

                  Text("2. Pilih Santri yang Siap Ujian", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  Obx(() => ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.daftarSiswa.length,
                    itemBuilder: (ctx, index) {
                      final siswa = controller.daftarSiswa[index];
                      final status = siswa.statusUjian;
                      return Obx(() {
                        final isSelected = controller.santriTerpilihUntukUjian.contains(siswa.nisn);
                        return CheckboxListTile(
                          title: Text(siswa.namaSiswa),
                          subtitle: Text("Status saat ini: ${status ?? 'Normal'}"),
                          value: isSelected,
                          onChanged: (status == 'siap_ujian') ? null : (val) {
                            controller.toggleSantriSelectionForUjian(siswa.nisn);
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: theme.colorScheme.primary,
                        );
                      });
                    },
                  )),
                ],
              ),
            ),
            
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isDialogLoading.value ? null : controller.tandaiSiapUjianMassal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(controller.isDialogLoading.value ? "Menyimpan..." : "Tandai Siap Ujian"),
              ),
            )),
            const SizedBox(height: 8), // Beri sedikit ruang di bawah
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showBulkUpdateDialog() {
    // Pastikan daftar pilihan kosong sebelum dialog dibuka
    controller.siswaTerpilihUntukUpdateMassal.clear(); 
    controller.bulkUpdateUmiC.clear();

    Get.defaultDialog(
      title: "Update UMI Massal",
      content: SizedBox(
        width: Get.width,
        height: Get.height * 0.5,
        child: Column(
          children: [
            // Dropdown untuk memilih level UMI tujuan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: DropdownSearch<String>(
                popupProps: const PopupProps.menu(showSearchBox: true),
                items: (f, cs) => controller.listLevelUmi, // <- Gunakan listLevelUmi
                onChanged: (value) => controller.bulkUpdateUmiC.text = value ?? '',
                decoratorProps: const DropDownDecoratorProps(
                  decoration: InputDecoration(
                    labelText: "Pilih Level UMI Tujuan",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            const Divider(),
            // Daftar siswa dengan checkbox
            Expanded(
              child: Obx(() => ListView.builder(
                itemCount: controller.daftarSiswa.length,
                itemBuilder: (context, index) {
                  final siswa = controller.daftarSiswa[index];
                  return Obx(() => CheckboxListTile(
                    title: Text(siswa.namaSiswa),
                    subtitle: Text("Level saat ini: ${siswa.ummi}"), // <- Gunakan field ummi
                    value: controller.siswaTerpilihUntukUpdateMassal.contains(siswa.nisn),
                    onChanged: (isSelected) {
                      if (isSelected == true) {
                        controller.siswaTerpilihUntukUpdateMassal.add(siswa.nisn);
                      } else {
                        controller.siswaTerpilihUntukUpdateMassal.remove(siswa.nisn);
                      }
                    },
                  ));
                },
              )),
            ),
          ],
        ),
      ),
      confirm: Obx(() => ElevatedButton(
        onPressed: controller.isDialogLoading.value 
          ? null 
          : () => controller.updateUmiMassal(), // <- Panggil fungsi Umi Massal
        child: controller.isDialogLoading.value
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text("Simpan Perubahan"),
      )),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text("Batal"),
      ),
    );
  }

  Widget _buildKeteranganSection(ThemeData theme) {
    final List<Map<String, String>> keteranganOptions = [
      { "title": "Lancar", "value": "Alhamdulillah, Ananda hari ini menunjukkan pemahaman yang sangat baik dan lancar. InsyaAllah, besok bisa melanjutkan ke materi berikutnya. Barokallohu fiik." },
      { "title": "Baik", "value": "Alhamdulillah, Ananda hari ini sudah baik dan lancar. Tetap semangat belajar ya, Nak. Barokallohu fiik." },
      { "title": "Perlu Pengulangan", "value": "Alhamdulillah, Ananda hari ini sudah ada peningkatan. Mohon untuk dipelajari kembali di rumah, materi hari ini akan kita ulangi pada pertemuan berikutnya. Semangat!" }
    ];

    return Obx(() => Column(
      children: keteranganOptions.map((option) {
        return RadioListTile<String>(
          title: Text(option['title']!, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          value: option['value']!,
          groupValue: controller.keteranganHalaqoh.value,
          onChanged: (val) { if (val != null) controller.keteranganHalaqoh.value = val; },
          activeColor: theme.colorScheme.primary,
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    ));
  }

  InputDecoration _inputDecorator(ThemeData theme, String label, IconData icon) {
     return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 22, color: theme.colorScheme.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _showInputNilaiMassalSheet(BuildContext context) {
    final theme = Theme.of(context);
    controller.clearNilaiForm();
    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      Container(
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container( margin: const EdgeInsets.only(bottom: 16), width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            Expanded(
              child: ListView(
                children: [
                  Text("1. Isi Template Nilai", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(controller: controller.suratC, decoration: _inputDecorator(theme, 'Surat Hafalan', Icons.book_outlined)),
                  const SizedBox(height: 12),
                  TextField(controller: controller.ayatHafalC, decoration: _inputDecorator(theme, 'Ayat yang Dihafal', Icons.format_list_numbered_rtl_outlined)),
                  const SizedBox(height: 12),
                  TextField(controller: controller.capaianC, decoration: _inputDecorator(theme, 'Capaian', Icons.flag_outlined)),
                  const SizedBox(height: 12),
                  TextField(controller: controller.materiC, decoration: _inputDecorator(theme, 'Materi UMMI/Al-Quran', Icons.lightbulb_outline)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.nilaiC,
                    decoration: _inputDecorator(theme, 'Nilai (Maks. 98)', Icons.star_border_outlined),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        int nilai = int.tryParse(value) ?? 0;
                        if (nilai > 98) {
                          controller.nilaiC.text = '98';
                          controller.nilaiC.selection = TextSelection.fromPosition(TextPosition(offset: controller.nilaiC.text.length));
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Text("Catatan Pengampu", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  _buildKeteranganSection(theme), // <-- FUNGSI YANG HILANG
                  const SizedBox(height: 24),
                  Text("2. Pilih Santri Penerima Nilai", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Obx(() => ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.daftarSiswa.length,
                    itemBuilder: (ctx, index) {
                      final santri = controller.daftarSiswa[index];
                      return Obx(() {
                        final isSelected = controller.santriTerpilihUntukNilai.contains(santri.nisn);
                        return CheckboxListTile(
                          title: Text(santri.namaSiswa),
                          subtitle: Text("Kelas: ${santri.kelas}"),
                          value: isSelected,
                          onChanged: (val) => controller.toggleSantriSelection(santri.nisn),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: theme.colorScheme.primary,
                        );
                      });
                    },
                  )),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => ElevatedButton.icon(
              icon: controller.isSavingNilai.value ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary)) : const Icon(Icons.save),
              label: Text(controller.isSavingNilai.value ? "Menyimpan..." : "Simpan untuk Santri Terpilih"),
              onPressed: controller.isSavingNilai.value ? null : controller.simpanNilaiMassal,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary),
            )),
          ],
        ),
      )
    );
  }

  /// Membangun tampilan saat daftar siswa masih kosong
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_add_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              "Belum Ada Siswa",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              "Kelompok ini masih kosong. Tambahkan siswa pertama Anda untuk memulai.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text("Tambah Siswa"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _showPilihKelasDialog, // Langsung panggil aksi
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun Card Siswa yang informatif dan interaktif
  Widget _buildSiswaCard(SiswaHalaqoh siswa) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          // Aksi utama: Buka halaman nilai siswa
          // Pastikan 'rawData' tersedia di model SiswaHalaqoh Anda
          Get.toNamed(Routes.DAFTAR_NILAI, arguments: siswa.rawData);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(children: [
            // Avatar Siswa
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blueGrey.shade50,
              backgroundImage: siswa.profileImageUrl != null
                  ? NetworkImage(siswa.profileImageUrl!)
                  : null,
              child: siswa.profileImageUrl == null
                  ? Text(
                      siswa.namaSiswa.isNotEmpty ? siswa.namaSiswa[0] : 'S',
                      style: const TextStyle(fontSize: 26, color: Colors.blueGrey),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Informasi Siswa
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(siswa.namaSiswa, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 4),
                Text("Kelas: ${siswa.kelas}", style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 8),
                // Chip untuk level UMI
                Chip(
                  label: Text("UMI: ${siswa.ummi}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: _getUmiColor(siswa.ummi), // Warna dinamis
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                Text("Capaian: ${siswa.capaian}"),
              ],
            )),
            // Tombol Aksi (Menu tiga titik)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'update') _showUpdateUmiDialog(siswa);
                if (value == 'pindah') _showPindahHalaqohDialog(siswa);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'update', child: Text('Update UMI')),
                const PopupMenuItem(value: 'pindah', child: Text('Pindah Halaqoh')),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  /// Dialog untuk mengupdate UMI (adaptasi dari Al-Husna)
  void _showUpdateUmiDialog(SiswaHalaqoh siswa) {
    controller.umiC.text = siswa.ummi; // Set nilai awal dari data siswa
    Get.defaultDialog(
      title: "Update UMI",
      content: Column(
        children: [
          Text(siswa.namaSiswa, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownSearch<String>(
            popupProps: const PopupProps.menu(showSearchBox: true),
            items: (f, cs) => controller.listLevelUmi, // Ambil list dari controller
            selectedItem: controller.umiC.text,
            onChanged: (value) => controller.umiC.text = value ?? '',
            decoratorProps: const DropDownDecoratorProps(
              decoration: InputDecoration(
                labelText: "Level UMI",
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
      confirm: Obx(() => ElevatedButton(
        onPressed: controller.isDialogLoading.value 
          ? null 
          : () => controller.updateUmi(siswa.nisn), // Panggil fungsi controller
        child: controller.isDialogLoading.value
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text("Simpan"),
      )),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }

  /// Dialog untuk memindahkan siswa (Anda bisa lengkapi nanti)
  void _showPindahHalaqohDialog(SiswaHalaqoh siswa) {
    // Implementasi dialog pindah, mirip dengan Al-Husna.
    // Anda perlu membuat fungsi `getTargetPengampu` di controller Anda.
    Get.defaultDialog(
      title: "Fitur Dalam Pengembangan",
      middleText: "Fitur untuk memindahkan siswa akan segera tersedia.",
      textConfirm: "OK",
      onConfirm: () => Get.back(),
    );
  }

  /// Dialog 1: Memilih Kelas (Alur Tambah Siswa)
  void _showPilihKelasDialog() {
    Get.defaultDialog(
      title: "Pilih Kelas",
      content: SizedBox(
        width: Get.width * 0.7,  // Beri lebar agar tidak terlalu besar
        height: Get.height * 0.3, // <-- LANGKAH 2: Beri TINGGI YANG PASTI
        child: FutureBuilder<List<String>>(
          future: controller.getKelasTersedia(), // Panggil fungsi controller
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text("Tidak ada kelas yang tersedia untuk fase ini.");
            }
            return SizedBox(
              width: Get.width * 0.7,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  String namaKelas = snapshot.data![index];
                  return ListTile(
                    title: Text(namaKelas),
                    onTap: () {
                      Get.back(); // Tutup dialog ini
                      _showPilihSiswaBottomSheet(namaKelas); // Buka dialog selanjutnya
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// Dialog 2: Memilih Siswa dari Kelas (Alur Tambah Siswa)
  void _showPilihSiswaBottomSheet(String namaKelas) {
    controller.kelasSiswaC.text = namaKelas; // Simpan kelas terpilih di controller
    Get.bottomSheet(
      Container(
        height: Get.height * 0.6,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          Text("Siswa dari Kelas $namaKelas", style: Get.textTheme.titleLarge),
          const Divider(),
          Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: controller.getSiswaBaruStream(namaKelas), // Panggil fungsi controller
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Semua siswa di kelas ini sudah memiliki kelompok."));
              }
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var dataSiswa = snapshot.data!.docs[index].data();
                  return ListTile(
                    title: Text(dataSiswa['namasiswa'] ?? 'Tanpa Nama'),
                    subtitle: Text("NISN: ${dataSiswa['nisn'] ?? ''}"),
                    trailing: Obx(() => controller.isDialogLoading.value 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green),
                          onPressed: () => controller.tambahSiswaKeHalaqoh(dataSiswa),
                        )),
                  );
                },
              );
            },
          )),
        ]),
      ),
      isScrollControlled: true,
    );
  }
}

/// Fungsi helper untuk memberi warna pada Chip UMI
Color _getUmiColor(String level) {
  final l = level.toLowerCase();
  if (l.contains('alquran')) return Colors.green.shade600;
  if (l.contains('jilid 6')) return Colors.blue.shade600;
  if (l.contains('jilid 5')) return Colors.purple.shade500;
  if (l.contains('jilid 4')) return Colors.deepOrange.shade500;
  if (l.startsWith('jilid')) return Colors.orange.shade700;
  return Colors.grey.shade500;
}
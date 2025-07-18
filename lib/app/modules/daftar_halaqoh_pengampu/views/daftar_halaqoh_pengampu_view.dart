// lib/app/modules/daftar_halaqoh_pengampu/views/daftar_halaqoh_pengampu_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../controllers/daftar_halaqoh_pengampu_controller.dart';

class DaftarHalaqohPengampuView extends GetView<DaftarHalaqohPengampuController> {
  const DaftarHalaqohPengampuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Halaqoh Pengampu'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.grey.shade800,

        actions: [
           Obx(() => 
            controller.daftarSantri.isNotEmpty
              ? PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'input_nilai') _showInputNilaiMassalSheet(context);
                    if (value == 'tandai_ujian') _showTandaiUjianSheet(context); // <-- Panggil fungsi baru
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'input_nilai', child: ListTile(leading: Icon(Icons.edit_note), title: Text('Input Nilai Massal'))),
                    const PopupMenuItem(value: 'tandai_ujian', child: ListTile(leading: Icon(Icons.assignment_turned_in), title: Text('Tandai Siap Ujian'))),
                  ],
                )
              : const SizedBox.shrink(),
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Widget untuk Pemilihan Kelompok Halaqoh ---
          _buildHalaqohSelector(),

          // --- WIDGET BARU UNTUK MENAMPILKAN TEMPAT ---
          _buildTempatInfo(),
          // ------------------------------------------
          
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              "Daftar Santri",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          // --- Widget untuk Menampilkan Daftar Santri ---
          Expanded(
            child: _buildSantriList(),
          ),
        ],
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

  void _showTandaiUjianSheet(BuildContext context) {
    final theme = Theme.of(context);
    controller.santriTerpilihUntukUjian.clear();
    controller.capaianUjianC.clear();
    controller.levelUjianC.clear();

    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 50, height: 5,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            Expanded(
              child: ListView(
                children: [
                  Text("1. Isi Detail Ujian", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(controller: controller.levelUjianC, decoration: _inputDecorator(theme, 'Level Ujian (Contoh: Jilid 1)', Icons.school)),
                  const SizedBox(height: 12),
                  TextField(controller: controller.capaianUjianC, decoration: _inputDecorator(theme, 'Capaian Terakhir Santri', Icons.flag), maxLines: 3),
                  const SizedBox(height: 24),
                  Text("2. Pilih Santri yang Siap Ujian", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Obx(() => ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.daftarSantri.length,
                    itemBuilder: (ctx, index) {
                      final santri = controller.daftarSantri[index];
                      // Pastikan model Anda sudah di-update untuk bisa membaca 'status_ujian'
                      final status = santri['status_ujian']; 
                      return Obx(() {
                        final isSelected = controller.santriTerpilihUntukUjian.contains(santri['id']);
                        return CheckboxListTile(
                          title: Text(santri['namasiswa']),
                          subtitle: Text("Status saat ini: ${status ?? 'Normal'}"),
                          value: isSelected,
                          onChanged: (status == 'siap_ujian') ? null : (val) {
                            controller.toggleSantriSelectionForUjian(santri['id']);
                          },
                          controlAffinity: ListTileControlAffinity.leading,
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
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: Text(controller.isDialogLoading.value ? "Menyimpan..." : "Tandai Siap Ujian"),
              ),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  
  // --- FUNGSI HELPER BARU UNTUK DEKORASI INPUT ---
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
            // Handle drag
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 50, height: 5,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            
            Expanded(
              child: ListView(
                children: [
                  // --- BAGIAN FORM TEMPLATE NILAI (DIPERCANTIK) ---
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

                  // --- BAGIAN CATATAN PENGAMPU (DIREVISI) ---
                  Text("Catatan Pengampu", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  _buildKeteranganSection(theme),
                  const SizedBox(height: 24),

                  // --- BAGIAN PEMILIHAN SANTRI (TETAP SAMA) ---
                  Text("2. Pilih Santri Penerima Nilai", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Obx(() => ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.daftarSantri.length,
                    itemBuilder: (ctx, index) {
                      final santri = controller.daftarSantri[index];
                      final nisn = santri['id'];
                      return Obx(() {
                        final isSelected = controller.santriTerpilihUntukNilai.contains(nisn);
                        return CheckboxListTile(
                          title: Text(santri['namasiswa']),
                          subtitle: Text("Kelas: ${santri['kelas']}"),
                          value: isSelected,
                          onChanged: (val) { controller.toggleSantriSelection(nisn); },
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: theme.colorScheme.primary,
                        );
                      });
                    },
                  )),
                ],
              ),
            ),

            // Tombol Simpan
            const SizedBox(height: 16),
            Obx(() => ElevatedButton.icon(
              icon: controller.isSavingNilai.value 
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary)) 
                  : const Icon(Icons.save),
              label: Text(controller.isSavingNilai.value ? "Menyimpan..." : "Simpan untuk Santri Terpilih"),
              onPressed: controller.isSavingNilai.value ? null : controller.simpanNilaiMassal,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            )),
          ],
        ),
      )
    );
  }

  /// Widget untuk menampilkan daftar kelompok halaqoh yang bisa dipilih.
  Widget _buildHalaqohSelector() {
    return Obx(() {
      if (controller.isLoadingHalaqoh.value) {
        return const Center(child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ));
      }

      if (controller.daftarHalaqoh.isEmpty) {
        return const Center(child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("Anda tidak mengampu kelompok halaqoh manapun."),
        ));
      }

      return SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: controller.daftarHalaqoh.length,
          itemBuilder: (context, index) {
            final namaHalaqoh = controller.daftarHalaqoh[index];
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Obx(() {
                final isSelected = controller.halaqohTerpilih.value == namaHalaqoh;
                return ChoiceChip(
                  label: Text(namaHalaqoh),
                  avatar: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      controller.gantiHalaqohTerpilih(namaHalaqoh);
                    }
                  },
                  selectedColor: Colors.teal.shade500,
                  backgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey.shade300)
                  ),
                );
              }),
            );
          },
        ),
      );
    });
  }

   /// Widget BARU untuk menampilkan informasi tempat.
  Widget _buildTempatInfo() {
    return Obx(() {
      // Tampilkan widget ini hanya jika sedang loading atau jika tempat sudah terpilih
      final tempat = controller.tempatTerpilih.value;
      final isLoading = controller.isLoadingSantri.value;

      if (isLoading) {
        // Tampilkan placeholder saat loading
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text("Mencari lokasi..."),
        );
      }

      if (tempat == null || tempat.isEmpty) {
        // Jangan tampilkan apa-apa jika tidak ada tempat
        return const SizedBox.shrink();
      }

      // Tampilkan info lokasi jika sudah ditemukan
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.teal.shade200)
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_outlined, color: Colors.teal.shade700, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                "Lokasi: $tempat",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Widget untuk menampilkan daftar santri berdasarkan kelompok yang dipilih.
  Widget _buildSantriList() {
    return Obx(() {
      if (controller.isLoadingSantri.value) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (controller.halaqohTerpilih.value == null) {
        return const Center(child: Text("Silakan pilih kelompok halaqoh."));
      }

      if (controller.daftarSantri.isEmpty) {
        return const Center(child: Text("Tidak ada santri di kelompok ini."));
      }
      
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: controller.daftarSantri.length,
        itemBuilder: (context, index) {
          final santri = controller.daftarSantri[index];
          return _SantriCard(santri: santri);
        },
      );
    });
  }
}


/// Widget Card kustom untuk setiap santri
class _SantriCard extends StatelessWidget {
  final Map<String, dynamic> santri;
  const _SantriCard({required this.santri});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String namaSantri = santri['namasiswa'] ?? 'Nama tidak ada';
    final String kelas = santri['kelas'] ?? 'Kelas tidak ada';
    final String nisn = santri['nisn'] ?? '';
    final String umi = santri['ummi'] ?? 'Belum ada';
    
    // --- BACA DARI FIELD BARU YANG DIBUAT CONTROLLER ---
    final String capaian = santri['capaian_untuk_view'] ?? '-';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if(nisn.isNotEmpty) {
             Get.toNamed(Routes.DAFTAR_NILAI, arguments: santri);
          } else {
            Get.snackbar("Info", "Siswa ini tidak memiliki NISN.");
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.teal.shade50,
                backgroundImage: NetworkImage("https://ui-avatars.com/api/?name=$namaSantri&background=81c784&color=fff&bold=true"),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(namaSantri, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    // INFORMASI KELAS
                    _buildInfoRow(theme, Icons.class_outlined, kelas),
                    const SizedBox(height: 4),
                    // INFORMASI UMI
                    _buildInfoRow(theme, Icons.menu_book_outlined, "UMI: $umi"),
                    const SizedBox(height: 4),
                    // INFORMASI CAPAIAN
                    _buildInfoRow(theme, Icons.star_border_outlined, "Capaian: $capaian"),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

   Widget _buildInfoRow(ThemeData theme, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text, 
            style: theme.textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
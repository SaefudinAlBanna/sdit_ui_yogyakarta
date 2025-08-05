// lib/app/widgets/input_nilai_massal_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../interfaces/input_nilai_massal_interface.dart';

// [WIDGET LENGKAP & DIPERBAIKI]
class InputNilaiMassalSheet extends StatelessWidget {
  final IInputNilaiMassalController controller;

  const InputNilaiMassalSheet({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    controller.clearNilaiForm();
    controller.nilaiMassalControllers.clear();
    for (var siswa in controller.daftarSiswa) {
      controller.nilaiMassalControllers[siswa.nisn] = TextEditingController();
    }
        return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // [LENGKAP] Handle di bagian atas
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: 50, height: 5,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
          ),
          Expanded(
            child: ListView(
               children: [
                       // Bagian Template Materi
                       Text("1. Isi Template Materi (Untuk Semua)", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                       const SizedBox(height: 16),
                       TextField(controller: controller.suratC, decoration: _inputDecorator(theme, 'Surat Hafalan', Icons.book_outlined)),
                       const SizedBox(height: 12),
                       TextField(controller: controller.ayatHafalC, decoration: _inputDecorator(theme, 'Ayat yang Dihafal', Icons.format_list_numbered_rtl_outlined)),
                       const SizedBox(height: 12),
                       TextField(controller: controller.capaianC, decoration: _inputDecorator(theme, 'Capaian', Icons.flag_outlined)),
                       const SizedBox(height: 12),
                       TextField(controller: controller.materiC, decoration: _inputDecorator(theme, 'Materi', Icons.lightbulb_outline)),
                       const SizedBox(height: 24),
                       // Bagian Catatan
                       Text("Catatan Pengampu", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                       _buildKeteranganSection(theme),
                       const SizedBox(height: 24),
                       // Bagian Pilih Siswa & Nilai
                       Text("2. Pilih Santri & Input Nilai Individual", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                       const SizedBox(height: 8),
                       Obx(() => ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.daftarSiswa.length,
                          itemBuilder: (ctx, index) {
                            final santri = controller.daftarSiswa[index];
                            return Obx(() {
                              final isSelected = controller.santriTerpilihUntukNilai.contains(santri.nisn);
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Checkbox(
                                  value: isSelected,
                                  onChanged: (val) => controller.toggleSantriSelection(santri.nisn),
                                  activeColor: theme.colorScheme.primary,
                                ),
                                title: Text(santri.namaSiswa),
                                trailing: SizedBox(
                                  width: 70,
                                  child: TextFormField(
                                    controller: controller.nilaiMassalControllers[santri.nisn],
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                                    decoration: const InputDecoration(hintText: "Nilai", isDense: true),
                                  ),
                                ),
                              );
                           });
                         },
                       )),
                     ],
            ),
          ),
          const SizedBox(height: 16),
          // [LENGKAP] Tombol Simpan
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
    );
  }

  // [DIPINDAHKAN & DIPERBAIKI] Helper UI sekarang menjadi bagian dari widget ini.
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
          // Akses controller dari properti kelas
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
}
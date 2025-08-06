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
    // [PERBAIKAN KUNCI #1] Gunakan DraggableScrollableSheet untuk UI yang bisa di-drag dan di-scroll
    return DraggableScrollableSheet(
      initialChildSize: 0.7, // Tinggi awal sheet (70% layar)
      minChildSize: 0.4,     // Tinggi minimal saat di-drag ke bawah
      maxChildSize: 0.95,    // Tinggi maksimal saat di-drag ke atas
      builder: (BuildContext context, ScrollController scrollController) {
        // scrollController ini akan kita teruskan ke ListView kita
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle untuk drag
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 50, height: 5,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
              
              // [PERBAIKAN KUNCI #2] Konten yang bisa di-scroll
              Expanded(
                child: ListView(
                  controller: scrollController, // Sambungkan controller dari DraggableScrollableSheet
                  children: [
                     // ... Semua konten form Anda masuk ke sini ...
                     Text("1. Isi Template Materi (Untuk Semua)", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                     const SizedBox(height: 16),
                     TextField(controller: controller.suratC, decoration: _inputDecorator(Theme.of(context), 'Surat Hafalan', Icons.book_outlined)),
                     const SizedBox(height: 12),
                     TextField(controller: controller.ayatHafalC, decoration: _inputDecorator(Theme.of(context), 'Ayat yang Dihafal', Icons.format_list_numbered_rtl_outlined)),
                     const SizedBox(height: 12),
                     TextField(controller: controller.capaianC, decoration: _inputDecorator(Theme.of(context), 'Capaian', Icons.flag_outlined)),
                     const SizedBox(height: 12),
                     TextField(controller: controller.materiC, decoration: _inputDecorator(Theme.of(context), 'Materi', Icons.lightbulb_outline)),
                     const SizedBox(height: 24),
                     Text("Catatan Pengampu", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                     _buildKeteranganSection(Theme.of(context)),
                     const SizedBox(height: 24),
                     Text("2. Pilih Santri & Input Nilai Individual", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                     const SizedBox(height: 8),
                     Obx(() => ListView.builder(
                        // [PERBAIKAN KUNCI #3] Konfigurasi ListView di dalam ListView
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
                                activeColor: Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(santri.namaSiswa),
                              trailing: SizedBox(
                                width: 70,
                                child: TextFormField(
                                  controller: controller.nilaiMassalControllers[santri.nisn],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                                  decoration: const InputDecoration(hintText: "Nilai", isDense: true),
                                ),
                              ),
                            );
                         });
                       },
                     )),
                     const SizedBox(height: 20), // Beri ruang di akhir list
                  ],
                ),
              ),

              // [PERBAIKAN KUNCI #4] Tombol yang selalu terlihat di bawah
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Obx(() => ElevatedButton.icon(
                  icon: controller.isSavingNilai.value 
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary)) 
                      : const Icon(Icons.save),
                  label: Text(controller.isSavingNilai.value ? "Menyimpan..." : "Simpan untuk Santri Terpilih"),
                  onPressed: controller.isSavingNilai.value ? null : controller.simpanNilaiMassal,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                )),
              ),
            ],
          ),
        );
      },
    );
  }


  // Helper UI tetap di sini, tidak ada perubahan
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
}


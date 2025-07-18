// lib/app/modules/jurnal_ajar_harian/views/jurnal_ajar_harian_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/jurnal_ajar_harian_controller.dart';

class JurnalAjarHarianView extends GetView<JurnalAjarHarianController> {
  const JurnalAjarHarianView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Jurnal Harian'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      // Gunakan floatingActionButton untuk tombol simpan agar selalu terlihat
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildSimpanButton(theme),
      
      // Body utama sekarang adalah satu form besar yang bisa di-scroll
      body: SingleChildScrollView(
        // Padding bawah agar tidak tertutup floating action button
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTanggalHariIni(theme),
            const SizedBox(height: 24),

            // --- BAGIAN BARU: PEMILIHAN KELAS ---
            _buildSectionHeader(theme, "1. Pilih Kelas yang Diajar"),
            _buildKelasSelector(),
            const SizedBox(height: 24),

            // --- BAGIAN BARU: PEMILIHAN JAM PELAJARAN ---
            _buildSectionHeader(theme, "2. Pilih Jam Pelajaran"),
            _buildJamPelajaranSelector(),
            const SizedBox(height: 24),

            // --- BAGIAN BARU: FORM INPUT ---
            _buildSectionHeader(theme, "3. Isi Detail Jurnal"),
            _buildJurnalForm(theme),
            const SizedBox(height: 32),

            // --- BAGIAN RIWAYAT (TETAP SAMA) ---
            const Divider(thickness: 1),
            const SizedBox(height: 16),
            Text(
              "Jurnal Tercatat Hari Ini",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildRiwayatJurnalHariIni(theme),
          ],
        ),
      ),
    );
  }

  //========================================================================
  // --- WIDGET-WIDGET BARU UNTUK UI DINAMIS ---
  //========================================================================

  /// Widget untuk menampilkan daftar kelas yang bisa dipilih.
  Widget _buildKelasSelector() {
    return FutureBuilder<List<String>>(
      future: controller.getDataKelasYangDiajar(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildErrorWidget(Get.theme, "Gagal memuat data kelas.");
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyStateWidget(Get.theme, "Anda tidak terdaftar mengajar di kelas manapun.");
        }
        
        // Obx akan "mendengarkan" perubahan pada `selectedKelasList`
        return Obx(() => Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: snapshot.data!.map((namaKelas) {
            final bool isSelected = controller.selectedKelasList.contains(namaKelas);
            return ChoiceChip(
              label: Text(namaKelas),
              selected: isSelected,
              onSelected: (selected) {
                // Panggil fungsi di controller untuk mengelola state
                controller.toggleKelasSelection(namaKelas);
              },
              selectedColor: Get.theme.colorScheme.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            );
          }).toList(),
        ));
      },
    );
  }

  /// Widget untuk menampilkan daftar jam pelajaran yang bisa dipilih.
  Widget _buildJamPelajaranSelector() {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: controller.getJamPelajaran(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildErrorWidget(Get.theme, "Gagal memuat jam pelajaran.");
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyStateWidget(Get.theme, "Jam pelajaran belum diatur admin.");
        }
        
        // Obx akan "mendengarkan" perubahan pada `selectedJamList`
        return Obx(() => Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: snapshot.data!.docs.map((doc) {
            String jamPelajaran = doc.data()['jampelajaran'] ?? doc.id;
            final bool isSelected = controller.selectedJamList.contains(jamPelajaran);
            return ChoiceChip(
              label: Text(jamPelajaran),
              selected: isSelected,
              onSelected: (selected) {
                controller.toggleJamSelection(jamPelajaran);
              },
              selectedColor: Get.theme.colorScheme.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            );
          }).toList(),
        ));
      },
    );
  }

  /// Widget untuk form input (mapel, materi, catatan).
  Widget _buildJurnalForm(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 16),
        
        // GetBuilder ini penting! Ia akan memaksa dropdown untuk
        // membangun ulang item-nya setiap kali pilihan kelas berubah.
        GetBuilder<JurnalAjarHarianController>(
          id: 'mapel-dropdown', // ID harus cocok dengan yang di controller
          builder: (_) {
            return Obx(() => DropdownSearch<String>(
              onChanged: controller.onMapelChanged,
              items: (f, cs) => controller.getDataMapel(),
              popupProps: _popupProps(theme, "Cari Mata Pelajaran"),
              decoratorProps: _dropdownDecorator(theme, 'Pilih Mata Pelajaran', Icons.book_outlined),
              enabled: controller.selectedKelasList.isNotEmpty,
              selectedItem: controller.selectedMapel.value,
            ));
          }
        ),

        const SizedBox(height: 16),
        TextField(
          controller: controller.materimapelC,
          decoration: _inputDecorator(theme, 'Materi yang Diajarkan', Icons.subject_outlined),
          textCapitalization: TextCapitalization.sentences,
          minLines: 2, maxLines: 4,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller.catatanjurnalC,
          decoration: _inputDecorator(theme, 'Catatan (Opsional)', Icons.notes_outlined),
          textCapitalization: TextCapitalization.sentences,
          minLines: 3, maxLines: 5,
        ),
      ],
    );
  }

  /// Widget untuk tombol simpan yang reaktif.
  Widget _buildSimpanButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Obx(() => ElevatedButton.icon(
        icon: controller.isSaving.value
            ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : const Icon(Icons.save_as_outlined),
        label: Text(controller.isSaving.value ? "Menyimpan..." : "Simpan Jurnal"),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          minimumSize: const Size(double.infinity, 50), // Tombol lebar penuh
          textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: controller.isSaving.value ? null : controller.simpanJurnal,
      )),
    );
  }

  //========================================================================
  // --- WIDGET-WIDGET LAMA YANG MASIH DIGUNAKAN (HELPER) ---
  //========================================================================
  
  // Widget _buildDaftarJamPelajaran dan _showInputJurnalBottomSheet sudah tidak diperlukan lagi.

  Widget _buildTanggalHariIni(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 22, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 10),
          Text(DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now()), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
      child: Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
  
  Widget _buildRiwayatJurnalHariIni(ThemeData theme) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: controller.getJurnalHariIni(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) { return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator())); }
        if (snapshot.hasError) { return _buildErrorWidget(theme, "Gagal memuat riwayat jurnal. ${snapshot.error}"); }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) { return _buildEmptyStateWidget(theme, "Belum ada jurnal yang Anda input hari ini."); }

        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            Map<String, dynamic> data = snapshot.data!.docs[index].data();
            DateTime tanggalInput = (data['tanggalinput'] as String?) != null ? DateTime.parse(data['tanggalinput'] as String) : DateTime.now();

            return Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(data['jampelajaran'] ?? 'Jam Pelajaran', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                        Text(DateFormat('HH:mm', 'id_ID').format(tanggalInput), style: theme.textTheme.bodySmall),
                      ],
                    ),
                    const Divider(height: 16),
                    _buildRichTextInfo("Kelas", data['kelas'] ?? '-'),
                    const SizedBox(height: 6),
                    _buildRichTextInfo("Mapel", data['namamapel'] ?? '-'),
                    const SizedBox(height: 6),
                    _buildRichTextInfo("Materi", data['materipelajaran'] ?? '-'),
                    if (data['catatanjurnal'] != null && (data['catatanjurnal'] as String).isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _buildRichTextInfo("Catatan", data['catatanjurnal'], isItalic: true),
                    ]
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRichTextInfo(String label, String value, {bool isItalic = false}) {
    final theme = Get.theme;
    return Text.rich(TextSpan(children: [
      TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
      TextSpan(text: value, style: TextStyle(fontStyle: isItalic ? FontStyle.italic : FontStyle.normal, color: theme.textTheme.bodySmall?.color)),
    ]), style: theme.textTheme.bodyMedium);
  }

  Widget _buildEmptyStateWidget(ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(message, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(ThemeData theme, String message) {
     return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text("Terjadi Kesalahan", style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.error)),
            const SizedBox(height: 8),
            Text(message, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecorator(ThemeData theme, String label, IconData icon) {
     return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 22),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
    );
  }

  DropDownDecoratorProps _dropdownDecorator(ThemeData theme, String label, IconData icon) {
    return DropDownDecoratorProps(
      decoration: _inputDecorator(theme, label, icon).copyWith(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
      ),
    );
  }

  PopupProps<String> _popupProps(ThemeData theme, String searchHint) {
    return PopupProps.menu(
      showSearchBox: true,
      searchFieldProps: TextFieldProps(decoration: _inputDecorator(theme, searchHint, Icons.search), style: theme.textTheme.bodyLarge),
      menuProps: MenuProps(borderRadius: BorderRadius.circular(12)),
      fit: FlexFit.loose,
      containerBuilder: (ctx, popupWidget) { return Material(elevation: 8, borderRadius: BorderRadius.circular(12), child: popupWidget); },
    );
  }
}